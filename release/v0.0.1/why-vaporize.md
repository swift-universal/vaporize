# Why Vaporize

**Status:** release-prep explainer
**Updated:** 2026-06-14T07:21:25Z
**Component:** `vaporize@wrkstrm-core.cli`
**Release target:** internal essential substrate CLI

## One Sentence Claim

Vaporize is better when the job is not merely "run Swift," but "turn typed
software intent into buildable, installable, reviewable world-state with a
stable assistant-facing command, receipts, and policy boundaries."

It is not a replacement for Swift, Xcode, or Xcode's build system. It is the
substrate-owned gate around those engines.

Internally, Vaporize provides engineering pedigree: it makes assistants fight
for the strongest available proof surface, from native Apple/Swift artifacts to
typed Kura records and release gates.

## Product Definition And Choice Argument

The product contract lives in `release/v0.0.1/product-definition.md`.

Choose Vaporize when the work is assistant-run, release-facing, app-facing,
receipt-bearing, toolchain-sensitive, project-migration, or shared-cache work.
Direct Swift remains reasonable for a human one-off local command, but Vaporize
is the better internal interface when the result must become reviewable
world-state.

## Problems Vaporize Claims To Solve

| Problem | Vaporize answer | Current proof |
| --- | --- | --- |
| Engineering standards drift into ad hoc proof | Vaporize makes the owned route prefer native artifacts, typed samples, receipts, and gates | Product definition, runtime sample series, release gates |
| Assistants improvise shell choreography | One canonical command surface for build, test, install, run, open, validate, inspect, import, generate, list targets, list workspace schemes, inventory, and toolchain selection | README, PRD FR-001 through FR-033, 23 CUJ bundles |
| Direct native tools bypass policy | `xcodebuild`, `xcrun`, and JSON validation details live behind Vaporize modes | CUJ-05, CUJ-06, release gates |
| Build/install output is hard to review | Receipts record what was requested and what happened | Pass/use/toolchain/validation/project receipts |
| Xcode project migration needs proof | YAML, Pkl, generated YAML, and first-slice `.xcodeproj` generation are compared and receipted | CUJ-08, CUJ-10, CUJ-11, CUJ-13, CUJ-14 |
| Apple project routing facts are guessed | `list-targets` emits target, package, scheme, and buildable-candidate facts from AppleProjectSpec before build/cache/parity routing | CUJ-18 |
| Maintained workspace schemes are guessed | `list-schemes` asks Xcode for live `.xcworkspace` schemes through `xcodebuild -list -json -workspace` before workspace build/cache routing | CUJ-20 |
| App artifact lookup is fragile | App bundle name, DerivedData, configuration, project/workspace, and install destination become explicit inputs | CUJ-02 |
| Huge workspace products are rebuilt locally | Shared workspace product-cache flags search the warm workspace DerivedData product before local outputs, `list-targets` names expected cache candidates and warm/missing state, and cache misses build through the shared workspace | CUJ-15, CUJ-19 |
| Release review drifts into chat memory | PRD, CUJs, gates, launch packet, provenance, and schema fixtures name the evidence and counts | Release v0.0.1 packet |

## Compared To Swift Alone

Swift is the compiler, package manager, and test runner. It remains the engine
for SwiftPM package work.

Vaporize adds:

- A stable CLI contract for assistants and runbooks.
- Toolchain selection through `toolchain -- swift ...` when the Xcode-selected
  Swift route is required.
- Install/uninstall/run wrappers for CLI and app artifacts.
- Receipt emission and release evidence integration.
- JSON validation, inventory scanning, CommonProcess `use`, and Apple project
  migration modes.
- App build/install composition that Swift alone does not own.

Current direct Swift comparison:

- On this host at `2026-06-13T21:39:03Z`, bare `swift --version` and
  `vaporize toolchain -- swift --version` both reported Apple Swift 6.4.
- A warm focused CUJ-15 test run took `6.80s` through bare `swift test` and
  `6.80s` through `vaporize toolchain -- swift test`.
- Therefore the current claim is not that Vaporize is faster than Swift for
  normal SwiftPM tests. The claim is that Vaporize makes the route stable,
  reviewable, policy-compliant, and composable with app/install/release work.

Swift alone is still fine for a human doing a local one-off package command.
Vaporize is the preferred internal route when an assistant is producing durable
evidence, installing artifacts, selecting Xcode Swift, touching app bundles, or
moving release state.

## Compared To Xcodebuild And Xcrun

`xcodebuild` is the low-level Apple build driver. It is powerful, but the raw
interface is too broad for assistant runbooks: small flag differences change
DerivedData, signing, destinations, result bundles, artifact names, and install
expectations.

Vaporize adds:

- Narrow typed inputs for project/workspace, scheme, configuration,
  destination, SDK, result bundle, build settings, app bundle name, and
  DerivedData.
- Early validation for invalid Xcode configuration.
- A consistent artifact lookup and install path after the build.
- Shared workspace product-cache behavior as a named feature instead of a
  hand-written `xcodebuild` convention.
- A policy boundary: assistants use Vaporize; Vaporize may invoke `xcodebuild`
  internally.

`xcrun` is the low-level tool selector. Vaporize's `toolchain` mode keeps that
tool selection inside the release surface and currently narrows it to Swift.
That prevents `toolchain` from becoming a generic native-tool bypass.

## Performance Benchmarks

These are current local baseline numbers, not final fleet benchmarks.

Environment:

- Generated at: `2026-06-13T21:39:03Z`
- Working tree: `/Users/sonoma/mono`
- Timing command: `/usr/bin/time -p`
- State: warm local SwiftPM build state, no clean build purge, no fleet
  DerivedData purge

| Benchmark | Command shape | Result |
| --- | --- | ---: |
| JSON validation | `vaporize validate-json --path launch-review-packet.json` | `0.03s real` |
| Xcode-selected Swift version | `vaporize toolchain -- swift --version` | `0.25s real` |
| Bare Swift version comparison | `swift --version` | `0.17s real` |
| Focused CUJ-15 through bare Swift | `swift test --filter VaporizeCUJ15XcodeProductCacheTests` | `6.80s real` |
| Focused CUJ-15 through Vaporize toolchain | `vaporize toolchain -- swift test --filter VaporizeCUJ15XcodeProductCacheTests` | `6.80s real` |
| Full Vaporize suite through Vaporize toolchain | `vaporize toolchain -- swift test` | Latest coverage model: 147 tests across 23 CUJ bundles after CUJ-14 graph/scheme generation, CUJ-17 follow-up coherence, CUJ-22 resource-bearing CLI install, and CUJ-23 product passport plus Pkl project-generation proving-ground additions; earlier `/usr/bin/time` baseline: `15.57s real`, 82 tests |
| Focused CUJ-09 with SwiftPM coverage enabled | `vaporize toolchain -- swift test --filter VaporizeCUJ09ReleaseReviewTests --enable-code-coverage` | `29.38s real`, 5 tests, SwiftPM codecov JSON verified |

Interpretation:

- Vaporize wrapper overhead is not visible at focused SwiftPM test scale in the
  warm CUJ-15 comparison; both routes measured `6.80s`.
- For a trivial version command, Vaporize's wrapper/toolchain route added about
  `0.08s real` in this run.
- The performance win Vaporize is positioned for is not raw compiler speed. It
  is avoiding repeated local app rebuilds, avoiding wrong toolchain runs,
  eliminating manual setup mistakes, and keeping evidence attached to the run.
- The CUJ-09 coverage run proves that Vaporize can stay on its owned toolchain
  route while SwiftPM emits native coverage artifacts: code coverage JSON,
  raw `.profraw` files, and merged `default.profdata`.

Runtime sample boundary:

- Manual `/usr/bin/time` output is provisional release-prep evidence.
- Queryable benchmark evidence belongs in the Kura series
  `private/universal/substrate/collectives/wrkstrm/private/universal/kura-spaces/series/vaporize-runtime-samples/`.
- Future measured claims should come from Vaporize-emitted runtime samples that
  attach Swift/Apple native artifacts: SwiftPM coverage JSON/profile data,
  xUnit output when available, `.xcresult` bundles, result metadata, build logs,
  diagnostics, DerivedData/product paths, and build-size metrics.
- Build size is a key runtime metric: samples should track build output,
  product bundle, executable binary, coverage artifact, result bundle, cache
  delta, and per-feature-flag size changes when a product exposes flags.
- App-facing samples should join the existing wrkstrm-core build-config stack:
  `tool-registry@wrkstrm-core.cli` `xcode-project` records for project
  ownership, `identifier@wrkstrm-core.cli` for app variant names/paths, and
  `app-artifacts@wrkstrm-core.cli` for bundle audits, install paths, and Xcode
  build/export receipts.

Benchmarks still required before final internal release:

- First-class Vaporize runtime sample emission into the Kura series.
- Durable artifact-retention policy for SwiftPM coverage data, xUnit output
  when available, Xcode `.xcresult` bundles, and DerivedData/product-cache
  evidence.
- Build-size baselines for app products, CLI binaries, coverage artifacts, and
  per-feature-flag cohorts.
- App build/config status samples that prove the Hello World-style path:
  registry `xcode-project` record -> identifier app description ->
  app-artifacts audit/export receipt -> Vaporize runtime sample.
- Cold app build: direct old path vs Vaporize path.
- Warm app build: cache hit vs cache miss.
- Shared workspace product-cache hit: install from warm workspace product
  without local rebuild.
- Workspace product-cache candidate discovery: expected `.app` product paths and
  warm/missing state from AppleProjectSpec target facts.
- Xcode workspace scheme listing: live scheme count, command duration, stdout
  size, stderr size, and timeout behavior for the maintained huge workspace.
- Shared workspace product-cache miss: build through workspace DerivedData and
  then install.
- Disk usage before and after local-per-project DerivedData is replaced by the
  shared workspace DerivedData product cache.
- Fleet-level timing across the owned Apple app surfaces.

## Build Space Savings

The product-cache feature is designed to reduce duplicate build products and
DerivedData growth when several projects already live in one large maintained
workspace.

Without the shared cache:

- Each app runbook can point at its own local DerivedData path.
- The same packages, modules, intermediates, and `.app` products can be rebuilt
  or retained in multiple per-project caches.
- Assistants have to guess which cache contains the product they need.

With the shared cache:

- The large workspace has one maintained DerivedData root.
- Vaporize first checks
  `Build/Products/<Configuration>/<product>.app` under that shared root.
- If the product is already warm, Vaporize installs it without a local rebuild.
- If the product is cold, Vaporize builds through the shared workspace and the
  same shared DerivedData path, so future projects read from the same cache.

The expected savings formula is:

```text
space_saved ~= sum(local per-project DerivedData products/intermediates retired)
               - additional growth in the shared workspace DerivedData
```

Current proof:

- CUJ-15 proves option parsing, paired option validation, cache-first lookup
  before local DerivedData, and shared workspace build invocation.
- CUJ-19 proves expected product-cache candidate path and warm/missing discovery
  from AppleProjectSpec target facts.
- CUJ-20 proves Xcode workspace scheme-listing request construction, JSON
  parsing, input validation, and receipt boundaries through
  `xcodebuild -list -json -workspace`.
- wrkstrm-core already has complementary app/build config tools:
  `tool-registry@wrkstrm-core.cli discover-apps` discovers `project.yml`
  app records, `identifier@wrkstrm-core.cli app describe` resolves canonical
  variant paths, and `app-artifacts@wrkstrm-core.cli` audits bundle IDs and
  builds/exports `.app` artifacts.

Not yet proven:

- Actual disk savings across the fleet.
- Which app products are already present in the large workspace.
- Automatic `.xcworkspace` graph membership discovery beyond AppleProjectSpec
  target facts.
- Large-workspace scheme-listing runtime and timeout behavior.
- Automatic Vaporize composition of registry, identifier, app-artifacts, and
  release-feature manifests into one app-facing runtime sample.

## User Ergonomics

Good ergonomics:

- One command family instead of remembering `swift`, `xcodebuild`, `xcrun`,
  `open`, install paths, JSON validation, and project migration utilities.
- Commands read like user intent: `build`, `install`, `run`, `use`,
  `toolchain`, `validate-json`, `inspect-project-yml`, `import-project-yml`,
  `generate-xcodeproj`, `list-targets`, `list-schemes`,
  `inspect-target-features`.
- Failure modes are named early: missing scheme, ambiguous project/workspace,
  malformed build setting, incomplete product-cache pair, missing app bundle.
- The same flags carry into release evidence, tests, and receipts.
- Cache behavior is explicit: callers name the shared workspace and the shared
  DerivedData root instead of relying on ambient Xcode state.
- App-facing config behavior is traceable: Vaporize can point back to the
  `xcode-project` registry record, identifier description, app-artifacts
  receipt, and release-feature/xcconfig source used for the build.

Tradeoffs:

- Vaporize has more surface area than a one-line `swift test`.
- It must stay ruthlessly documented, tested by CUJ, and honest about what is
  first-slice versus fleet-proven.
- If a task is purely local human experimentation, direct Swift can be simpler.
  If the task is assistant-run, release-facing, app-facing, receipt-bearing,
  toolchain-sensitive, project-migration, or shared-cache work, Vaporize is the
  better interface.

## Bottom Line

Vaporize is better because it turns a fragile collection of powerful native
tools into one substrate-owned build and proof surface. It preserves Swift and
Xcode as engines, but makes the assistant-facing path predictable, auditable,
install-aware, migration-aware, and cache-aware.

The current benchmark evidence supports a modest, honest claim: Vaporize adds
little overhead for warm SwiftPM proof runs and creates room for much larger
space/time wins through shared workspace product-cache reuse. The fleet
performance and disk-space claims still need dedicated benchmark receipts before
they can become final release claims.
