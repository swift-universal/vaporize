#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
package_directory=$(dirname -- "$script_directory")
product="vaporize.cli@wrkstrm-core.clia.sh"
manual_date=${MANUAL_DATE:-$(date -u '+%Y-%m-%d')}
manual_authors=${MANUAL_AUTHORS:-Wrkstrm Core}
destination_directory="$package_directory/Documentation/man/man1"

generate_manual() {
  "$@" package generate-manual \
    --configuration debug \
    --date "$manual_date" \
    --authors "$manual_authors"
}

cd "$package_directory"
if [ "${VAPORIZE_USE_XCODE_SWIFT:-0}" = "1" ]; then
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "VAPORIZE_USE_XCODE_SWIFT is available only on macOS." >&2
    exit 2
  fi
  generate_manual /usr/bin/xcrun swift
else
  generate_manual swift
fi

generated_page="$package_directory/.build/plugins/GenerateManual/outputs/$product/$product.1"
if [ ! -f "$generated_page" ]; then
  echo "Generated manual was not found at $generated_page" >&2
  exit 1
fi

mkdir -p "$destination_directory"
# ArgumentParser's ToolInfo dump injects a synthetic `help` subcommand even
# when the runtime command tree is a leaf. GenerateManual consequently emits a
# required `.Ar subcommand` that is not present in Vaporize's live usage.
normalized_page=$(mktemp "${TMPDIR:-/tmp}/vaporize-manual.XXXXXX")
trap 'rm -f "$normalized_page"' EXIT HUP INT TERM
sed '/^\.Ar subcommand$/d' "$generated_page" > "$normalized_page"
install -m 0644 "$normalized_page" "$destination_directory/$product.1"
rm -f "$normalized_page"
trap - EXIT HUP INT TERM
printf '.so man1/%s.1\n' "$product" > "$destination_directory/vaporize.1"
printf '.so man1/%s.1\n' "$product" > "$destination_directory/vaporize@wrkstrm-core.cli.1"

if command -v mandoc >/dev/null 2>&1; then
  mandoc -Tutf8 "$destination_directory/$product.1" >/dev/null
fi
