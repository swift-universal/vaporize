#!/usr/bin/env bash
#
# End-to-end proof for `vaporize self-update --product <name>` (component C of
# FR-CLI-SPARKLE-SELF-UPDATE-VAPORIZE-PKL-SCAFFOLDER-2026-07-14).
#
# Proves the CRUX the unit tests (tests/cuj-29-product-self-update) cannot:
# vaporize — updating ANOTHER installed tool, not itself — resolves the tool's
# ~/.swiftpm/bin binary + metadata sidecar, fetches a real HTTP appcast,
# EdDSA-verifies the signed enclosure, atomically swaps the installed bytes,
# and records the new version in the sidecar. Then the mandatory negative: a
# wrong-key feed is REFUSED and the installed tool is untouched.
#
# The fixture tool is swift-cli-updater's updater-proving-ground (it prints its
# compiled-in version and doubles as the genkey/sign crypto helper), reusing
# the sibling package's prove.sh conventions.
#
# Exits non-zero on any failure (loud, per the no-silent-fallback axiom).

set -euo pipefail

VAPORIZE_PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
UPDATER_PKG="$(cd "$VAPORIZE_PKG/../../../../../swift-universal/private/universal/domain/tooling/spm/swift-cli-updater" && pwd)"
VERSION_FILE="$UPDATER_PKG/Sources/updater-proving-ground/Version.swift"
PG_BIN="$UPDATER_PKG/.build/release/updater-proving-ground"
PORT="${PG_PORT:-8974}"

FIXTURE="pg-lane-c-e2e-fixture"
BIN_DIR="$HOME/.swiftpm/bin"
INSTALLED="$BIN_DIR/$FIXTURE"
SIDECAR_DIR="$BIN_DIR/$FIXTURE.metadata"

WORK="$(mktemp -d)"
SERVE="$WORK/serve"; mkdir -p "$SERVE"
HTTP_PID=""
ORIGINAL_VERSION_LINE="$(grep PG_VERSION_MARKER "$VERSION_FILE")"

cleanup() {
  [[ -n "$HTTP_PID" ]] && kill "$HTTP_PID" 2>/dev/null || true
  sed -i '' "s|.*PG_VERSION_MARKER|$ORIGINAL_VERSION_LINE|" "$VERSION_FILE" 2>/dev/null || true
  rm -f "$INSTALLED"
  rm -rf "$SIDECAR_DIR"
  rm -rf "$WORK"
}
trap cleanup EXIT

set_version() {
  sed -i '' "s|static let value = \"[^\"]*\" // PG_VERSION_MARKER|static let value = \"$1\" // PG_VERSION_MARKER|" "$VERSION_FILE"
}

write_sidecar() {  # $1 = version, $2 = public key
  mkdir -p "$SIDECAR_DIR"
  cat > "$SIDECAR_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>$FIXTURE</string>
	<key>CFBundleShortVersionString</key><string>$1</string>
	<key>SUFeedURL</key><string>http://localhost:$PORT/appcast.xml</string>
	<key>SUPublicEDKey</key><string>$2</string>
</dict>
</plist>
PLIST
}

echo "== [0] build vaporize (the updater of OTHER tools) =="
( cd "$VAPORIZE_PKG" && swift build --product 'vaporize.cli@wrkstrm-core.clia.sh' >/dev/null )
VAPORIZE="$VAPORIZE_PKG/.build/debug/vaporize.cli@wrkstrm-core.clia.sh"
[[ -x "$VAPORIZE" ]] || { echo "FAIL: vaporize binary missing"; exit 1; }

echo "== [1] build fixture v2.0.0 (enclosure + crypto helper) =="
set_version "2.0.0"
( cd "$UPDATER_PKG" && swift build -c release --product updater-proving-ground >/dev/null )
cp "$PG_BIN" "$WORK/pg-v2"
[[ "$("$WORK/pg-v2" version)" == "2.0.0" ]] || { echo "FAIL: v2 build not 2.0.0"; exit 1; }

echo "== [2] genkey + package + sign the enclosure =="
read -r PRIV PUB < <("$WORK/pg-v2" genkey)
STAGE="$WORK/stage"; mkdir -p "$STAGE"
cp "$WORK/pg-v2" "$STAGE/$FIXTURE"
( cd "$STAGE" && zip -q -X "$SERVE/enclosure.zip" "$FIXTURE" )
SIG="$("$WORK/pg-v2" sign "$PRIV" "$SERVE/enclosure.zip")"
LEN="$(stat -f%z "$SERVE/enclosure.zip")"
[[ -n "$SIG" ]] || { echo "FAIL: empty signature"; exit 1; }

echo "== [3] build fixture v1.0.0 and install it with a self-update sidecar =="
set_version "1.0.0"
( cd "$UPDATER_PKG" && swift build -c release --product updater-proving-ground >/dev/null )
mkdir -p "$BIN_DIR"
cp "$PG_BIN" "$INSTALLED"
chmod 755 "$INSTALLED"
write_sidecar "1.0.0" "$PUB"
[[ "$("$INSTALLED" version)" == "1.0.0" ]] || { echo "FAIL: installed fixture not 1.0.0"; exit 1; }

echo "== [4] write appcast + serve =="
cat > "$SERVE/appcast.xml" <<XML
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>
    <title>$FIXTURE</title>
    <item>
      <title>2.0.0</title>
      <enclosure url="http://localhost:$PORT/enclosure.zip"
                 sparkle:version="2.0.0"
                 sparkle:edSignature="$SIG"
                 length="$LEN"
                 type="application/octet-stream"/>
    </item>
  </channel>
</rss>
XML
lsof -ti ":$PORT" 2>/dev/null | xargs kill -9 2>/dev/null || true
python3 -m http.server "$PORT" --directory "$SERVE" >/dev/null 2>&1 &
HTTP_PID=$!
for _ in $(seq 1 50); do
  if curl -sf "http://localhost:$PORT/appcast.xml" >/dev/null 2>&1; then break; fi
  sleep 0.1
done

echo "== [5] vaporize self-update --product $FIXTURE =="
OUT="$("$VAPORIZE" self-update --product "$FIXTURE" 2>&1)" || {
  echo "$OUT"; echo "FAIL: vaporize self-update exited non-zero on the positive path"; exit 1; }
echo "---- self-update output ----"
echo "$OUT"
echo "----------------------------"

echo "== [6] positive assertions =="
FAILED=0

if echo "$OUT" | grep -q "updated 1.0.0 -> 2.0.0"; then
  echo "PASS: vaporize reported the 1.0.0 -> 2.0.0 swap"
else
  echo "FAIL: no update report in vaporize output"; FAILED=1
fi

if cmp -s "$INSTALLED" "$WORK/pg-v2"; then
  echo "PASS: installed binary bytes now equal the v2 enclosure payload"
else
  echo "FAIL: installed binary was not swapped to v2 bytes"; FAILED=1
fi

NOW="$("$INSTALLED" version)"
if [[ "$NOW" == "2.0.0" ]]; then
  echo "PASS: installed tool now reports 2.0.0"
else
  echo "FAIL: installed tool reports $NOW"; FAILED=1
fi

SIDE_VER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SIDECAR_DIR/Info.plist")"
if [[ "$SIDE_VER" == "2.0.0" ]]; then
  echo "PASS: sidecar CFBundleShortVersionString recorded 2.0.0"
else
  echo "FAIL: sidecar version is $SIDE_VER"; FAILED=1
fi

echo "== [7] negative: WRONG-KEY sidecar must be REFUSED, tool unchanged =="
set_version "1.0.0"
( cd "$UPDATER_PKG" && swift build -c release --product updater-proving-ground >/dev/null )
cp "$PG_BIN" "$INSTALLED"
chmod 755 "$INSTALLED"
read -r _WRONG_PRIV WRONG_PUB < <("$WORK/pg-v2" genkey)   # a DIFFERENT keypair
write_sidecar "1.0.0" "$WRONG_PUB"

set +e
NEG_OUT="$("$VAPORIZE" self-update --product "$FIXTURE" 2>&1)"
NEG_STATUS=$?
set -e
echo "---- wrong-key output ----"
echo "$NEG_OUT"
echo "--------------------------"

if [[ "$NEG_STATUS" -ne 0 ]]; then
  echo "PASS: wrong-key update exited non-zero"
else
  echo "FAIL: wrong-key update exited zero"; FAILED=1
fi

if echo "$NEG_OUT" | grep -qi "REFUSED"; then
  echo "PASS: wrong-key update refused loudly"
else
  echo "FAIL: no loud REFUSED in output"; FAILED=1
fi

NEG_NOW="$("$INSTALLED" version)"
if [[ "$NEG_NOW" == "1.0.0" ]]; then
  echo "PASS: unverified bytes not installed; tool still on 1.0.0"
else
  echo "FAIL: tool changed to $NEG_NOW despite failed verification"; FAILED=1
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo ""
  echo "PRODUCT SELF-UPDATE E2E PROVEN: vaporize swapped another tool's verified update; wrong-key update refused."
else
  echo ""
  echo "PRODUCT SELF-UPDATE E2E FAILED"
fi
exit "$FAILED"
