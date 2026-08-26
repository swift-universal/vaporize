# Vaporize v0.0.1 - Critical User Journeys

**Status:** release-prep draft; blocked pending fleet Pkl project-generation parity
**Updated:** 2026-08-25T21:30:00Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Product-Level User Journey Map

`release/v0.0.1/product-definition.md` defines the product-level journeys that
shape this CUJ set. Each active CUJ is a targetable release proof for at least
one product-level journey.

| Product-level journey | CUJ proof |
| --- | --- |
| Assistant builds, installs, or runs SwiftPM CLI/app software without composing shell choreography | CUJ-01, CUJ-02, CUJ-22 |
| Assistant validates release JSON without direct `jq` | CUJ-06 |
| Assistant uses Xcode-selected Swift without direct `xcrun` | CUJ-05 |
| Assistant emits receipts for CommonProcess command execution | CUJ-03, CUJ-04 |
| Assistant inventories vaporware state from substrate records | CUJ-07 |
| Assistant migrates Apple project generation from legacy `project.yml` toward Pkl-backed truth with receipts at every boundary | CUJ-08, CUJ-10, CUJ-11, CUJ-13, CUJ-14 |
| Assistant discovers Apple project targets, buildable candidates, packages, and schemes before routing build/cache/parity work | CUJ-18, CUJ-20 |
| Assistant reuses a warm Xcode workspace product cache instead of rebuilding locally when the shared product already exists | CUJ-15, CUJ-19 |
| Release reviewer evaluates product definition, PRD review session, vaporware modification request discipline, user journeys, choice argument, evidence, gates, and blockers without relying on chat memory | CUJ-09 |
| Assistant audits release-spine coherence before trusting a vaporware packet | CUJ-17 |
| Assistant gates every journey-derived CUJ state record with proof before release review trusts the simulated world | CUJ-21 |
| Assistant installs resource-bearing SwiftPM CLIs that use `Bundle.module` without depending on live build products | CUJ-22 |
| Assistant adopts a proving-ground passport before release review trusts a vaporware product | CUJ-23 |
| Assistant trusts that a reported-success install actually landed the artifact (fail-loud + atomic swap) | CUJ-24 |
| Assistant audits CUJ coverage across canonical product homes and active-owned implementation projects without hand scans | CUJ-25 |
| Assistant uses one canonical ledger to find executable CUJ proofs, saved green receipts, and remaining proof obligations | CUJ-26 |
| Assistant inspects CUJ coverage and next actions for every active-owned implementation project without reducing the census to aggregate counts | CUJ-27 |
| Developer chooses maintained source or an admitted provisioned dependency product under one temporal requirement | CUJ-28, CUJ-29, CUJ-39 |
| Client receives a typed product miss while an authorized producer may provision and retry once | CUJ-30 |
| Developer refreshes discovery, explicitly adopts a compatible update, or builds offline without hidden graph mutation | CUJ-31 |
| Release and platform owners preserve distinct contextual SwiftPM resolutions instead of overwriting one root lock file | CUJ-32 |
| Client retrieves a large admitted payload without committing it to Git or exposing producer-private information | CUJ-33, CUJ-34 |
| Release owner proves a full source-closure build rather than treating product-first development as release proof | CUJ-35 |
| Operator follows a correlated package-supply state machine and recovers truthful terminal state after interruption | CUJ-36 |
| Portfolio owner sees requested, resolved, and provisioned X-of-Y build coverage without putting analytics in the build's critical path | CUJ-37 |
| Platform owner supplies a platform-specific manifest and proves its services through a separate OS test suite | CUJ-38 |
| Existing user invokes Vaporize with the library-product feature disabled and receives exact legacy behavior | CUJ-40 |
| Developer explicitly enables the experiment and builds/tests a SwiftPM library product through a sibling service | CUJ-41 |
| Product owner reviews experiment analytics, decides, and closes only after flag and dead-branch removal | CUJ-42 |

## CUJ-01 - Assistant Builds And Installs A SwiftPM CLI

1. Assistant receives a concrete SwiftPM package path and product name.
2. On macOS, assistant runs `vaporize build swift --artifact cli
   --package-path <package> --product <product>` or its adjacent `build xcode`
   sibling. On hosts without Xcode, assistant runs the collapsed
   `vaporize build --artifact cli ...` command.
3. Vaporize builds the product in the requested configuration.
4. Unless `--skip-install` is present, Vaporize installs the CLI through the
   owned Swift package install lane.
5. Assistant reports the command, configuration, and result.

Success:

- The assistant does not hand-compose `swift build` plus install commands.
- The build/install route is repeatable and uses one Vaporize invocation chain.
- A failed macOS authority prints the exact sibling retry without losing the
  original options.
- Phase output and the typed test receipt distinguish maintainer preparation,
  subprocess execution, and package restoration.

Failure truth:

- If the package path or product is missing, the assistant records the missing
  typed input and does not invent a product by grepping broad directories.

## CUJ-02 - Assistant Builds And Launches A Mac App

1. Assistant receives a Mac app package or project home.
2. Assistant runs `vaporize install xcode --artifact app` with the package path,
   product, project or workspace, scheme, destination, and build settings.
3. Vaporize performs the build through its app installer route.
4. Vaporize installs the app bundle at the requested destination.
5. If `--launch` is present, Vaporize opens the installed app.

Success:

- Direct `xcodebuild` remains inside Vaporize.
- App bundle name differences are represented with `--app-bundle-name`, not
  guessed from Finder state.

Failure truth:

- If the app home still requires XcodeGen/project generation, final internal
  release stays blocked by
  `FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl`
  rather than smuggling an ad-hoc XcodeGen pre-step.

## CUJ-03 - Assistant Runs A Swift Proof Command With A Receipt

1. Assistant needs a Swift command that is not a build/install/open wrapper.
2. Assistant runs `vaporize pass --analyze --receipt-path <receipt> -- swift <args>`.
3. Vaporize executes through CommonProcess.
4. Vaporize preserves stdout, stderr, and process exit semantics.
5. Vaporize emits a receipt containing the tool, executable, arguments,
   working directory, request id, runner kind, exit status, pid, and byte counts.

Success:

- The proof command is observable and repeatable.
- The assistant can cite a receipt instead of pasting unstructured terminal
  chatter.

## CUJ-04 - Assistant Uses A CommonProcess Invocation Directly

1. Assistant or upstream tooling constructs a CommonProcess `CommandSpec` JSON.
2. Assistant runs
   `vaporize use --common-process-spec <spec.json> --receipt-path <receipt>`.
3. Vaporize decodes and validates the `CommandSpec`.
4. Vaporize executes the command through `RunnerControllerFactory`.
5. Vaporize emits a `vaporize-use-common-process` receipt without leaking
   environment values.

Success:

- `use` is not another shell passthrough; the typed CommonProcess invocation is
  the contract.
- Downstream tooling can invoke Vaporize using a stable process model rather
  than Vaporize-specific argv choreography.

Failure truth:

- Invalid specs fail at validation before execution.
- Non-zero process exits propagate as non-zero Vaporize exits.

## CUJ-05 - Assistant Selects Swift Or Xcode Independently

1. Assistant needs to report or change the active default Swift selection.
2. Assistant runs `vaporize toolchain-selection swift -- use [options] [selector]`.
3. On macOS, Xcode developer-directory selection remains independent and uses
   `vaporize toolchain-selection xcode -- select <args>`.
4. Vaporize invokes its compiled Swiftly `use` implementation or
   `/usr/bin/xcode-select`; it does not launch an installed Swiftly CLI.
5. Vaporize can emit a `vaporize-toolchain-selection` receipt when requested.

Success:

- Swift selection does not mutate Xcode selection, and Xcode selection does not
  mutate default Swift selection.
- Lifecycle, inspection, and execution requests fail at the selection parser
  boundary instead of turning selection into a generic toolchain command.
- Xcode-selected Swift execution, when needed for a package operation, remains
  under `install`, `build`, `test`, or `run` with its adjacent macOS-only
  `xcode` authority; hosts without Xcode expose the collapsed Swift command.
- `tests/proving-grounds/core-command-authority` passes through both macOS
  authorities with Swift Testing. Retained receipts name `default-swift` and
  `xcrun-xcode-select`, preserve exact sibling commands, and report phase
  timings. This proves authority routing, not a general compiler-speed claim.

## CUJ-06 - Assistant Validates Release Packet JSON Without jq

1. Assistant creates or updates a release packet JSON file.
2. Assistant runs `vaporize validate-json --path <packet.json>`.
3. Vaporize parses the file through the Swift Universal json-formatter package.
4. Vaporize prints a concise validity result and can emit a
   `vaporize-json-validation` receipt when requested.

Success:

- The assistant does not call `jq` directly for release packet validation.
- Invalid JSON is caught before launch review consumes the packet.

## CUJ-07 - Assistant Inventories Vaporware State

1. Assistant receives a record tree or component home.
2. Assistant runs `vaporize status --path <records> --format text` for human
   review or `vaporize warehouse --path <records> --receipt-path <receipt.json>`
   for durable evidence.
3. Vaporize scans JSON files and classifies collapse state.
4. Assistant uses the inventory to choose the next collapse or file a bead.

Success:

- The assistant does not run broad manual grep to count vapor annotations.
- Legacy `x-craze-collapse-path` records remain visible while forward docs name
  `x-vaporize-collapse-path`.

## CUJ-08 - Assistant Inspects Legacy XcodeGen Project YAML

1. Assistant receives a legacy XcodeGen `project.yml` during the Pkl migration.
2. Assistant runs
   `vaporize inspect-project-yml --path <project.yml> --format json --receipt-path <receipt>`.
3. Vaporize parses the YAML into Swift `AppleProjectSpec` data.
4. Vaporize emits a `vaporize-apple-project-yml-inspection` receipt with
   project, target, package, and scheme counts.
5. Assistant uses the receipt to choose the next parity or migration step.

Success:

- The assistant does not invoke XcodeGen directly.
- The bridge is read-only: no YAML rewrite, no pbxproj generation, no release
  claim that YAML remains the forward source of truth.
- Pkl migration work gets a tested Swift intake shape before world-state
  generation is attempted.

Failure truth:

- If the YAML cannot be parsed into the supported read model, Vaporize reports
  the failure and the migration stays blocked rather than silently generating
  partial project state.

## CUJ-09 - Release Reviewer Reads The Packet

1. Reviewer opens `release/v0.0.1/product-definition.md`.
2. Reviewer checks that the product definition names primary users, product-level
   journeys, why users choose Vaporize, when not to choose Vaporize, and build
   implications.
3. Reviewer opens `release/v0.0.1/prd.md`.
4. Reviewer opens `release/v0.0.1/prd-review-session.md` and checks that the
   Engineering, QA, and Marketing PRD review requirement exists before future
   coding starts.
5. Reviewer opens
   `vaporize.engineering.docc/vaporware-modification-request-discipline.md` and
   checks that behavior-changing vaporware modification requests require a
   feature flag or feature-status story, targetable tests, and release evidence.
6. Reviewer opens this CUJ file and checks that each critical journey has
   success and failure truth.
7. Reviewer opens `release/v0.0.1/release-gates.md`.
8. Reviewer opens `release/v0.0.1/evidence/launch-review-packet.json`.
9. Reviewer verifies that Vaporize is classified as an internal essential tool,
   not a public release artifact.
10. Reviewer decides whether v0.0.1 is approved, blocked, or conditionally ready.

Success:

- Release review is based on current product definition, PRD review status,
  vaporware modification request discipline, user journeys, choice argument,
  artifacts, tests, and known blockers, not chat memory.

## CUJ-10 - Assistant Compares Legacy YAML With Pkl Specimen

1. Assistant ports one legacy `project.yml` into a Pkl record that amends
   `AppleProjectSpec.pkl`.
2. Assistant runs
   `vaporize compare-project-yml-pkl --path <project.yml> --pkl-path <project.pkl> --receipt-path <receipt>`.
3. Vaporize evaluates the Pkl record through PklSwift.
4. Vaporize decodes both legacy YAML and PklSwift output into Swift
   `AppleProjectSpec`.
5. Vaporize emits a `vaporize-apple-project-yml-pkl-comparison` receipt.

Success:

- The comparison reports zero mismatches before any generator writes project
  world-state.
- A mismatch blocks the next migration step and names the mismatched signature
  section.

Failure truth:

- A matched comparison is parity evidence for one specimen only; it is not
  fleet build parity and not Pkl-backed project generation.

## CUJ-11 - Assistant Generates Transitional YAML From Pkl

1. Assistant has a Pkl parity specimen for one owned Apple app.
2. Assistant runs
   `vaporize generate-project-yml --pkl-path <project.pkl> --output-path <generated.yml> --receipt-path <receipt>`.
3. Vaporize evaluates the Pkl record through PklSwift.
4. Vaporize writes transitional `AppleProjectSpec` YAML to the requested output
   path.
5. Vaporize emits a `vaporize-pkl-project-yml-generation` receipt.
6. Assistant runs `compare-project-yml-pkl` against the generated YAML and Pkl
   specimen to prove round-trip parity.

Success:

- Generated YAML exists, decodes through `AppleProjectYMLReader`, and compares
  back to Pkl with zero mismatches.
- The generation receipt explicitly records that `.xcodeproj` world-state was
  not generated.

Failure truth:

- This is transitional YAML generation. It does not prove final buildable
  project generation, fleet parity, or internal release readiness.

## CUJ-12 - Assistant Runs Package Graph Analysis Through Vaporize

1. Assistant needs package graph analysis while staying inside the Vaporize
   tool boundary.
2. Assistant runs `vaporize graph -- <package-graph-args>`.
3. Vaporize resolves `package-graph@wrkstrm.cli` and forwards the remaining
   arguments without interpreting them as Vaporize options.
4. Assistant receives package graph output from the canonical Vaporize surface.

Success:

- The assistant does not call `package-graph@wrkstrm.cli` as a separate
  primary tool when the release surface says Vaporize owns the lane.
- Forwarded arguments remain package-graph arguments rather than being
  consumed by Vaporize's parser.

Failure truth:

- If the package graph package cannot be resolved, Vaporize reports the
  resolution failure instead of silently falling back to a broad repository
  scan.

## CUJ-13 - Assistant Imports Legacy YAML Into Pkl

1. Assistant receives a legacy XcodeGen `project.yml` during the Pkl migration.
2. Assistant runs
   `vaporize import-project-yml --path <project.yml> --output-path <project.pkl> --receipt-path <receipt>`.
3. Vaporize parses YAML into Swift `AppleProjectSpec` data.
4. Vaporize renders an AppleProjectSpec Pkl specimen that amends
   `AppleProjectSpec.pkl`.
5. Vaporize emits a `vaporize-apple-project-yml-pkl-import` receipt.
6. Assistant runs `compare-project-yml-pkl` to prove the imported Pkl still
   matches the source YAML.

Success:

- The generated Pkl evaluates through PklSwift.
- The generated Pkl compares back to the source YAML with zero mismatches.
- The import receipt explicitly records that `.xcodeproj` world-state was not
  generated.

Failure truth:

- This is a migration import bridge, not a claim that YAML remains canonical.
- A successful import does not prove buildable project generation or fleet
  migration readiness.

## CUJ-14 - Assistant Generates Expanded Xcode Project World-State From Pkl

1. Assistant has an AppleProjectSpec Pkl specimen for a substrate-owned macOS
   application, framework, tool, or unit-test target graph.
2. Assistant runs
   `vaporize generate-xcodeproj --pkl-path <project.pkl> --output-path <generated.xcodeproj> --receipt-path <receipt>`.
3. Vaporize evaluates the Pkl record through PklSwift.
4. Vaporize renders deterministic `.xcodeproj` package world-state, including
   `project.pbxproj`, `project.xcworkspace/contents.xcworkspacedata`, target
   dependencies, linked and embedded framework phases, local package product
   dependencies, and shared `xcshareddata/xcschemes/*.xcscheme` files.
5. Vaporize projects typed release identity into Xcode build settings when the
   target declares bundle id, marketing version, build version, generated
   Info.plist, or Sparkle feed/signing keys.
6. Vaporize emits a `vaporize-pkl-xcodeproj-generation` receipt.

Success:

- The generated `.xcodeproj` exists on disk with project, target, source phase,
  settings, product reference, and post-build script entries.
- The receipt explicitly records that buildable world-state and Xcode project
  generation were performed.
- Source paths are resolved from the Pkl file's project home, not from the
  chosen output directory.
- macOS tool targets generate executable product references without a fake
  `.app` suffix.
- Framework, application, unit-test, local package, and shared-scheme graph
  generation has expected-pass coverage.
- The renderer is deterministic for the same evaluated spec and source tree.

Failure truth:

- Missing non-optional source paths fail the generation with the target name and
  missing source path.
- Unsupported target types fail explicitly instead of silently becoming a
  supported target type.
- This expanded slice does not yet prove fleet build parity, all XcodeGen
  feature parity, Sparkle appcast generation, or final internal release
  readiness.

## CUJ-15 - Assistant Reuses A Warm Xcode Workspace Product Cache

1. Assistant knows the target app also exists in a large Xcode workspace that
   is kept warm by regular builds.
2. Assistant runs `vaporize install xcode --artifact app` with the normal app
   package/project identity plus `--xcode-product-cache-workspace` and
   `--xcode-product-cache-derived-data-path`.
3. Vaporize checks the shared DerivedData product path before local DerivedData
   and SwiftPM build output candidates.
4. If the shared app product already exists, Vaporize installs that product
   without rebuilding the local project.
5. If the shared product is not warm, Vaporize builds through the shared
   workspace and shared DerivedData path using the requested scheme.

Success:

- The huge workspace can act as the product cache for every project it contains.
- Local app installs do not rebuild when the shared workspace cache already has
  the requested `.app` product.
- Cache workspace and cache DerivedData options are accepted only as a pair.
- A local project/workspace path may still describe the app home while the
  actual build invocation uses the shared cache workspace.

Failure truth:

- This does not yet discover schemes/products automatically from the workspace.
- This does not prove the whole fleet is present in the large workspace cache.
- A cold or stale cache falls back to the shared workspace build path, not to
  an untyped direct `xcodebuild` run.

## CUJ-16 - Assistant Audits wrkstrm App Minimums

1. Assistant receives a wrkstrm-owned app path or an `xcode-project.tool.json`
   record.
2. Assistant asks Vaporize to inspect wrkstrm app minimums for that app.
3. Vaporize resolves the app registry record, project spec, build
   configurations, release-feature manifest, generated xcconfigs, project
   config wiring, generated `ReleaseFeatures.swift`, and
   `digikoma-release-features` provenance.
4. Vaporize emits a machine-readable app-minimums receipt and a concise human
   status report.

Success:

- Vaporize reports whether the app has `Config/release-features.json`.
- Vaporize reports whether every declared tier has a generated
  `Config/xcconfigs/<XcodeConfig>.xcconfig`.
- Vaporize reports whether project `configFiles` or Pkl equivalent wiring
  points at those generated xcconfigs.
- Vaporize reports whether generated `Sources/ReleaseFeatures.swift` exists.
- Vaporize reports generator provenance from receipts or generated headers.
- Missing, stale, or unknown minimums block strong app-facing claims about
  release tiers, feature cohorts, launch readiness, and per-feature size.

Failure truth:

- v0.0.1 implements target-level inspection for XcodeGen `project.yml`
  `configFiles`, `release-features.json`, generated xcconfigs, generated
  `ReleaseFeatures.swift`, and generated-file provenance.
- Fleet registry-level inspection from `xcode-project.tool.json` records remains
  a follow-up.
- Hello World Google is the reference specimen, not proof that the fleet already
  meets the minimum.

## CUJ-17 - Assistant Runs Release Doctor Before Trusting The Packet

1. Assistant receives a Vaporize package root or `release/v0.0.1` root.
2. Assistant runs `release-doctor --path <package-or-release-root>`.
3. Vaporize resolves the release spine and checks required artifacts, evidence
   JSON, PRD/CUJ/gate/catalog alignment, launch-review references, provenance,
   and CUJ coverage.
4. Vaporize emits a `vaporize-release-doctor` receipt and concise status.
5. Assistant treats a passing receipt as release-spine coherence evidence, not
   final release approval.

Success:

- Required product, PRD, CUJ, gate, launch-review, provenance, CUJ coverage,
  feature catalog, and engineering DocC artifacts exist.
- Release evidence JSON parses without direct `jq`.
- Launch-review packet includes `GATE-33-release-doctor` and a release-doctor
  receipt evidence ref.
- Provenance inventories the release-doctor receipt.
- CUJ coverage counts CUJ-17 and the `VaporizeCUJ17ReleaseDoctorTests` bundle.

Failure truth:

- A release-doctor pass can coexist with final release blockers.
- The command audits spine coherence; it does not run every build, benchmark,
  or fleet parity proof.
- Periodic vaporware buddy health, automatic runtime samples, and build-watch
  repair loops are follow-up features.

## CUJ-18 - Assistant Discovers Project Targets Through Vaporize

1. Assistant receives an Apple project directory, legacy `project.yml`, or
   AppleProjectSpec Pkl specimen.
2. Assistant runs `vaporize list-targets --package-path <project-dir>` or
   `vaporize list-targets --pkl-path <project.pkl>`.
3. Vaporize reads the selected AppleProjectSpec source.
4. Vaporize emits a `vaporize-project-target-discovery` receipt that names
   target, package, scheme, and buildable-candidate facts.
5. Assistant uses the receipt to choose the next parity, build, install, cache,
   or migration route.

Success:

- Directory input prefers `project.pkl` and falls back to `project.yml`.
- The receipt names target kinds, source paths, configuration names,
  post-build-script presence, package names, scheme names, and buildable target
  candidates.
- Creative Selection v0.2 proves target discovery from the forward Pkl
  specimen before deeper workspace-cache discovery is attempted.

Failure truth:

- A directory without `project.pkl` or `project.yml` fails at the project-spec
  boundary.
- This first slice discovers routing facts. It does not build, install,
  generate `.xcodeproj` world-state, infer the whole workspace product cache, or
  prove fleet parity.

## CUJ-19 - Assistant Discovers Workspace Product Cache Candidates

1. Assistant receives an AppleProjectSpec source and a maintained workspace
   cache pair.
2. Assistant runs `vaporize list-targets` with
   `--xcode-product-cache-workspace`, `--xcode-product-cache-derived-data-path`,
   and `--configuration`.
3. Vaporize discovers buildable AppleProjectSpec targets.
4. Vaporize maps each buildable target's product name to the expected shared
   DerivedData `.app` product path.
5. Vaporize emits warm/missing status for each cache candidate in the
   `vaporize-project-target-discovery` receipt.

Success:

- The receipt names the shared workspace path, DerivedData root,
  configuration, candidate count, warm count, app bundle path, target name,
  product name, and status.
- Warm products are reported when the expected `.app` path exists.
- Missing products are reported without falling back to direct build commands.
- Non-buildable targets do not create app product-cache candidates.
- Incomplete workspace/DerivedData option pairs fail before discovery.

Failure truth:

- This slice derives candidate paths from AppleProjectSpec target facts and the
  shared DerivedData layout.
- It does not parse `.xcworkspace` membership, run `xcodebuild`, install apps,
  warm the cache, prove that the whole fleet is present, or measure disk
  savings.

## CUJ-20 - Assistant Lists Xcode Workspace Schemes Through Xcodebuild

1. Assistant receives the maintained Xcode workspace path.
2. Assistant runs
   `vaporize list-schemes --xcode-workspace <workspace.xcworkspace>`.
3. Vaporize executes `xcodebuild -list -json -workspace <workspace>` through
   the CommonProcess runner.
4. Vaporize parses Xcode's workspace scheme list.
5. Vaporize emits text or a `vaporize-xcode-workspace-scheme-list` receipt so
   downstream build/cache routing can choose a real workspace scheme.

Success:

- The command validates that the input is a `.xcworkspace` path.
- The request uses `xcodebuild -list -json -workspace` as the workspace graph
  authority.
- The parser extracts the workspace name and non-empty scheme list from Xcode's
  JSON output.
- The receipt records workspace path, scheme count, schemes, xcodebuild
  arguments, working directory, request ID, runner kind, developer-directory
  override status, process result, and proof boundaries.

Failure truth:

- This slice lists workspace schemes only.
- It does not build, install, warm caches, inspect product paths, measure
  runtime, prove fleet cache coverage, or replace AppleProjectSpec target
  discovery.
- The first live probe against the large `rismay-substrate.xcworkspace`
  exceeded the interactive investigation window and was stopped without a
  receipt; runtime/timeout behavior for the huge maintained workspace remains a
  follow-up measurement target.

## CUJ-21 - Assistant Gates Every CUJ State Record With Proof

1. Assistant derives CUJ-state records from complete critical user journeys.
2. Assistant attaches a proof entry to every required CUJ-state id.
3. Vaporize writes or reviews a `cuj-state-coverage` evidence document.
4. Release doctor audits the coverage status, required state ids, proof floor,
   uncovered ids, unknown ids, and duplicate proof ids.
5. Release review fails the slice if any CUJ-state record lacks proof.

Success:

- The coverage document names `stateFamily: cuj-state`.
- `requiredStateIDs` is non-empty.
- Every required state id appears in the proof set.
- `uncoveredStateIDs`, `unknownStateIDs`, and `duplicateProofStateIDs` are empty.
- The release packet includes `release/v0.0.1/evidence/cuj-state-coverage.json`.

Failure truth:

- This proves journey-derived state coverage, not database adapter readiness.
- Kura, Turso, libSQL, sync, production migrations, and public availability remain
  separate integration or release claims.

## CUJ-22 - Assistant Installs A Resource-Bearing SwiftPM CLI

1. Assistant receives a SwiftPM CLI package whose executable target declares
   `.process("resources")` or `.copy("resources")`.
2. The CLI reads those resources with `Bundle.module`.
3. A raw `swift package experimental-install` installs the executable but does
   not carry the target resource bundle next to the installed binary.
4. Vaporize installs the same product through `install`, asks
   SwiftPM for the build products directory with `swift build --show-bin-path`,
   and copies direct `.bundle` siblings into `~/.swiftpm/bin`.
5. The installed CLI runs after `.build` is hidden and prints the resource
   value from the installed resource bundle.

Success:

- A typed simulation proving-ground manifest names every CUJ-22 scenario and
  fails coverage when a scenario receipt is missing.
- Processed resources and copied resource directories both work away from the
  build products directory.
- JSON resources can be decoded through `Bundle.module` after install.
- Larger byte-count resources can be read through `Bundle.module` after install.
- Reinstall replaces a stale installed resource bundle with the fresh build
  product.
- A checked-in lowercase resource-vault proving-ground CLI installs through
  Vaporize and reads nested copied JSON/text resources after `.build` is hidden.
- Existing legacy resource-bearing CLIs with noncanonical product names are
  captured at Vaporize's product gate with an actionable canonical suggestion.
- Product version/build data is represented by Vaporize's CLI metadata sidecar
  rather than pretending the bare executable has an app-style Info.plist.

Failure truth:

- This proves SwiftPM CLI resource-bundle carry and product metadata sidecar
  behavior only.
- It does not make CLIs into app bundles, does not make
  `Bundle.main.infoDictionary` expose Vaporize product metadata, and does not
  prove Sparkle appcast generation, update signing, or runtime update delivery.

## CUJ-23 - Assistant Adopts Product Proving-Ground Passport

1. Assistant receives or creates a vaporware product that needs release-review
   evidence.
2. Assistant identifies the product class, owning bead, CUJs, and expected
   proving-ground tracks for that class.
3. Assistant records a typed product proving-ground profile with scenarios,
   targetable test bundle refs, receipt refs, release-doctor check refs, and
   explicit boundaries.
4. Vaporize audits the profile before release review trusts the product.

Success:

- The product proving-ground profile has document kind
  `vaporware-product-proving-ground-profile`.
- The profile names the product class, owning bead, CUJs, required tracks,
  scenarios, release-doctor checks, targetable tests, and receipt refs.
- The adoption gate passes when every required track is covered and every
  scenario has a targetable test bundle and receipt ref.
- Product class defaults exist for CLI, app, library, workflow, generator,
  assistant, and site products.
- A Pkl project-generation proving-ground passport names CUJ-14 and CUJ-23
  evidence for skid-pad, hill-climb, crash-barrier, inspection-bay, and
  prototype-track scenarios.
- Release Doctor checks FR-033, CUJ-23, GATE-40, the engineering doc, launch
  review evidence, and the CUJ-23 targetable test bundle.

Failure truth:

- Missing required tracks fail the passport.
- Missing CUJ refs fail the passport.
- Missing receipt refs fail the passport.
- Missing targetable test bundles fail the passport.
- Unknown track slugs fail the passport.
- This proves adoption evidence shape only. Product-specific behavior still
  needs product-specific proving-ground scenarios.

## Test Coverage Contract

Test count is derived from PRD requirements through the active draft CUJs.
The executable Swift suite is allowed to exceed this number, but release gates
must know the required floor.

| CUJ | PRD refs | Required Swift test obligations |
| --- | --- | ---: |
| CUJ-01 | FR-001, FR-002, FR-004 | 5 |
| CUJ-02 | FR-003, FR-004, FR-015 | 9 |
| CUJ-03 | FR-005 | 4 |
| CUJ-04 | FR-006 | 4 |
| CUJ-05 | FR-010 | 11 |
| CUJ-06 | FR-011 | 3 |
| CUJ-07 | FR-007, FR-008 | 10 |
| CUJ-08 | FR-015 | 5 |
| CUJ-09 | FR-012, FR-013, FR-014, FR-022, FR-025, FR-026 | 0 Swift tests; 7 release evidence checks |
| CUJ-10 | FR-016 | 5 |
| CUJ-11 | FR-017 | 3 |
| CUJ-12 | FR-009 | 1 |
| CUJ-13 | FR-018 | 5 |
| CUJ-14 | FR-020 | 7 |
| CUJ-15 | FR-003, FR-021 | 4 |
| CUJ-16 | FR-023, FR-024 | 5 Swift tests; 1 release evidence check |
| CUJ-17 | FR-027 | 7 Swift tests; 1 release evidence check |
| CUJ-18 | FR-028 | 5 Swift tests; 1 release evidence check |
| CUJ-19 | FR-021, FR-029 | 5 Swift tests; 1 release evidence check |
| CUJ-20 | FR-030 | 5 |
| CUJ-21 | FR-031 | 6 Swift tests; 1 release evidence check |
| CUJ-22 | FR-002, FR-032 | 8 |
| CUJ-23 | FR-033 | 4 Swift tests; 1 release evidence check |
| CUJ-24 | FR-020 | 3 |
| CUJ-25 | FR-007, FR-008 | 4 |
| CUJ-26 | FR-034 | 5 |
| CUJ-27 | FR-035 | 4 Swift tests; 1 release evidence check |

Current active-CUJ requirement:

- Required Swift test obligations: 132
- Required release evidence checks: 14
- Required targetable test obligations: 146
- Current executable Swift tests: 196 across 26 implemented CUJ-specific SwiftPM
  bundles (CUJ-24 remains focused inside the CUJ-02 app-install target)
- Coverage artifact:
  `release/v0.0.1/evidence/cuj-test-coverage.json`
- CUJ-state coverage artifact:
  `release/v0.0.1/evidence/cuj-state-coverage.json`

### Requirements-Defined Package-Supply Journeys

CUJ-28 through CUJ-42 are product-line requirements, not v0.0.1 executable
claims. They do not enter the 132-test or 14-evidence-check floor above until a
pre-code PRD review fixes their targetable test obligations and Schema Universal
contracts. Until then, release evidence must report them as
`requirements-defined; implementation-pending`, never `proven`.

## CUJ-24 - Assistant Trusts Install Integrity

1. Assistant runs a Vaporize install (`--artifact cli` or `--artifact app`).
2. Vaporize performs the build and install through its owned install lane.
3. Vaporize verifies the artifact actually landed at the install path.
4. On CLI-install success, Vaporize prints `verified <product> installed at <path>`.
5. If nothing landed, Vaporize fails loud rather than reporting a silent success.

Acceptance:

- CLI install fails with a typed error when no executable lands at the install
  path after `experimental-install`, and prints a verified-installed
  confirmation on success (the visibility that surfaces a missing binary in a
  multi-product suite reinstall).
- App install stages to a same-volume sibling then atomically swaps
  (`replaceItemAt` when replacing, `moveItem` for a fresh install), so an aborted
  copy never leaves a missing install; fails loud
  (`InstallerError.installVerificationFailed`) if nothing landed; leaves no
  `.installing-` staged residue.
- Simulated by `VaporizeCUJ24InstallIntegrityTests` (atomic install lands +
  leaves no residue; forced reinstall replaces atomically; unforced install over
  an existing bundle refuses loudly).
- Backs `BUG-VAPORIZE-CLI-INSTALL-NO-POST-INSTALL-PRESENCE-CHECK-2026-07-08` and
  the `tooling-silent-fallback-to-wrong-state-not-error-loud` axiom.

## CUJ-25 - Assistant Audits The CUJ Portfolio

1. Assistant runs `vaporize.cli@wrkstrm-core.clia.sh cuj-audit --path <substrate>`.
2. Vaporize inventories canonical product homes and active-owned build surfaces
   through the existing owned-surface model.
3. Vaporize classifies standalone typed definitions, legacy JSON collections,
   Markdown and DocC journeys, matrices, receipts, manifests, fixtures, trees,
   and Swift test proofs as distinct artifact classes.
4. Vaporize binds definitions to their owning project and records structural
   issues, declared or matched proof evidence, and zero-CUJ product homes.
5. Assistant saves the JSON receipt and Markdown report outside temporary
   storage, then uses the exact gap list to author the next CUJs.

Acceptance:

- Dependency checkouts, generated projects, derived state, and external
  references do not inflate the active-owned implementation denominator.
- Schema fixtures, journey trees, coverage matrices, scenario receipts, and
  tests remain visible but never masquerade as standalone product definitions.
- Compact CUJs receive structural checks, including the proven-state proof and
  last-proven requirements.
- `VaporizeCUJ25PortfolioAuditTests` proves CLI parsing, artifact-class
  separation, canonical zero-CUJ detection, legacy multi-journey retention,
  proof matching, and malformed proven-state reporting.
- A substrate-wide JSON receipt and readable report are saved in the
  `vaporware-cuj-state-workstream` evidence home.

## CUJ-26 - Assistant Uses The Canonical Automated-Proof Ledger

1. Assistant runs `cuj-audit` with `--proof-ledger-path` set to the canonical
   `vaporware-cuj-state-workstream` automated-proofs path.
2. Vaporize reads each CUJ's declared proof references and resolves the named
   Swift Testing type and method in the owning implementation package.
3. Vaporize accepts saved evidence only from receipt-like JSON with an explicit
   green result; partial, failing, declarative, schema, matrix, and launch-packet
   mentions do not become green proof.
4. Vaporize classifies every journey as missing-binding, binding-only,
   executable-bound, evidence-backed, proven, or invalid-proven-claim and emits
   concrete obligations for every missing leg.
5. Assistant saves the typed ledger at its canonical workflow home and uses it
   to evolve proof coverage without moving executable tests or owning receipts.

Acceptance:

- The canonical ledger is
  `private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/workflows/vaporware-cuj-state-workstream/v0.1.0/automated-proofs/cuj-automated-proof-ledger.su.json`.
- Executable tests remain in owning implementation packages; green execution
  receipts remain in owning proving-ground or release evidence homes.
- Strict `proven` requires a declared proof reference, a resolvable executable
  test, saved green evidence, and a last-proven Chronon ID.
- Status-3 records that do not satisfy all four legs are reported as invalid
  proven claims; the tool does not manufacture evidence or chronons.
- The ledger validates against the schema-universal
  `cuj-automated-proof-ledger` schema and states that automated proof cannot
  approve a human review gate.
- `VaporizeCUJ26AutomatedProofLedgerTests` proves path parsing, executable proof
  resolution, rejection of partial evidence, strict proven state, obligation
  emission, and JSON round-trip behavior.

## CUJ-27 - Assistant Inspects Every Implementation Project's CUJ Coverage

1. Assistant runs `cuj-audit` with both `--project-ledger-path` and
   `--project-ledger-csv-path` set to saved workflow evidence homes.
2. Vaporize groups active-owned Package.swift, Xcode project, Xcode workspace,
   project.yml, and project.pkl surfaces into one implementation-project row per
   canonical home.
3. Vaporize maps each row to product records using explicit path overlap or a
   unique product-name match and records the method and confidence.
4. Vaporize associates definitions by composite `(projectKey, definitionID)`
   identity, because CUJ ID labels are not globally unique across projects.
5. Vaporize computes typed, binding, executable, evidence, chronon, structural,
   and strict proof legs; proof states; obligations; completion basis points;
   coverage band; and quantified next actions for each row.
6. Assistant uses the JSON, CSV, or board portfolio register to inspect exact
   projects and rollups without replacing the project census with a few totals.

Acceptance:

- Every active-owned implementation project appears exactly once and retains
  every exact implementation surface path.
- Harness runtime `jobs/` snapshots, dependency checkouts, generated outputs,
  derived state, external references, and projections do not inflate the
  denominator.
- Unmapped no-CUJ rows receive an applicability-classification action; mapped
  no-CUJ rows receive an author-or-link action. Infrastructure is not forced to
  invent a journey before applicability is classified.
- Definition identity is project-qualified, while the summary separately names
  project-qualified records, distinct ID labels, reused labels, and project-CUJ
  associations.
- Owner, domain, surface-kind, mapping-confidence, coverage-band, and action-kind
  rollups remain derivable from the project rows.
- The JSON validates against schema-universal and the CSV has one header plus
  one row per project.
- `VaporizeCUJ27ProjectCoverageLedgerTests` proves CLI paths, one-row-per-project
  dimensions, CSV completeness, typed JSON round trip, rollups, and boundaries.

## CUJ-28 - Developer Selects Maintained Local Source

1. A developer requests a logical dependency with a Calendar-Origin temporal
   `from:` requirement and chooses the source representation.
2. Vaporize resolves the maintained `pri` source home as a canonical in-place
   checkout without changing the dependency identity or compatibility range.
3. SwiftPM computes the graph for the command's platform, architecture,
   configuration, toolchain, and release channel.
4. Vaporize records the contextual resolution and runs maintainer/source gates
   before compiling.

Acceptance:

- Source selection never rewrites the dependency as a product-only identity.
- The direct-local route creates no SwiftPM editable checkout; any legacy
  maintainer edit-mode cleanup cannot restore away an explicitly adopted
  resolution update.
- Process execution uses CommonProcess.

## CUJ-29 - Developer Consumes An Admitted Provisioned Product

1. A developer selects product representation for a compatible dependency.
2. Vaporize checks local and permitted remote `pro` Git records for a compatible
   admitted build matching the derived build context.
3. It verifies admission, integrity, privacy, and payload availability.
4. SwiftPM consumes the provisioned product without compiling that dependency
   from source, while the active root package continues to build from source.

Acceptance:

- Git is the temporal catalog and admission ledger.
- An artifact digest verifies the selected payload; it does not select the
  dependency.
- The receipt distinguishes a true product hit from a source build.

## CUJ-30 - Client Receives ProvisioningRequired Or Producer Provisions Once

1. Vaporize finds no compatible admitted product for the requested context.
2. In client mode, it returns typed `ProvisioningRequired` with the missing
   context and does not compile or publish private source.
3. In an authorized producer mode, it builds from source, verifies the output,
   admits the contextual resolution and product record, and retries lookup once.
4. The retry either returns the admitted product or a typed terminal failure.

Acceptance:

- Client and producer authority are explicit policy, not inferred from a
  writable directory.
- Provisioning cannot retry indefinitely.
- Only a trusted admission lane publishes `pro` state.

## CUJ-31 - Developer Controls Freshness And Adoption

1. The developer chooses `locked`, `refresh`, `update-compatible`, or `offline`.
2. `refresh` fetches or inspects Git refs without pulling into the user's
   working tree and reports newer compatible candidates.
3. `update-compatible` explicitly adopts a compatible candidate and permits
   SwiftPM to update the contextual resolution projection.
4. `locked` holds the admitted selection; `offline` uses only locally available
   admitted records and payloads.

Acceptance:

- Discovery, selection, and adoption are separate recorded states.
- A fetch never silently changes `Package.resolved` or the active graph.
- An offline miss is typed and explains which local record or payload is absent.

## CUJ-32 - Release Owner Preserves A Contextual Resolution Matrix

1. A release owner requests builds across two or more platform, architecture,
   configuration, toolchain, channel, or dependency-representation contexts.
2. SwiftPM computes `Package.resolved` for each supplied context.
3. Vaporize captures and validates each resolution as a separately keyed
   artifact, then admits the trusted records to Git.
4. The root `Package.resolved` remains only the current working projection.

Acceptance:

- Parallel builds cannot overwrite another context's admitted resolution.
- A missing client context returns `ProvisioningRequired` rather than borrowing
  a similar but incompatible lock file.
- The producer and admission lane are named in the receipt.

## CUJ-33 - Client Retrieves A Depot-Backed Payload

1. Vaporize selects an admitted Git record whose payload is stored in the
   optional artifact depot.
2. The record supplies the payload coordinate, expected size, and integrity
   evidence.
3. Vaporize retrieves or reuses the payload, verifies it, and makes it available
   to the provisioned package contract.
4. The receipt binds the Git admission record to the verified depot payload.

Acceptance:

- The depot is a data plane behind Git, not a competing version selector.
- Artifacts at or above 100 MiB are never committed to Git.
- A missing, truncated, or mismatched payload fails before consumption.

## CUJ-34 - Provisioner Blocks Private-Information Leakage

1. An authorized producer prepares a candidate `pro` repository or depot
   payload from a `pri` source build.
2. Vaporize scans manifest metadata, paths, logs, symbols, environment-derived
   values, and packaging inputs at the provision boundary.
3. Any producer source path, username, environment secret, private topology,
   raw receipt/log, signing material, or prohibited debug information blocks
   admission.
4. A clean candidate receives a privacy-gate receipt that can be referenced by
   the admitted build record.

Acceptance:

- Redaction after publication is not considered a passing strategy.
- Privacy evidence records categories and findings without copying the secret.
- `pro` remains private and client-facing; it is not public merely because it
  omits source.

## CUJ-35 - Release Owner Rebuilds The Full Closure From Source

1. A release owner selects a large-product release channel and source-closure
   policy.
2. Vaporize resolves the admitted temporal graph, materializes trusted source
   for every dependency, and builds the complete closure in the requested
   configuration.
3. It verifies the release products and records source provenance for every
   dependency.
4. The release receipt explicitly distinguishes this build from product-first
   developer acceleration.

Acceptance:

- A product-first development receipt cannot satisfy the source-closure gate.
- Release channel and debug/release configuration remain separate axes.
- Debug/release is derived from the Vaporize/SwiftPM command context, not baked
  into each logical dependency declaration.

## CUJ-36 - Operator Follows And Recovers The Supply State Machine

1. An operator starts a package-supply operation and receives one correlation
   identity across CommonLog, Service Context, Distributed Tracing, events, and
   the final receipt.
2. Vaporize records requested, resolution discovery, selection, artifact lookup,
   hit/miss, build, verification, admission, and terminal transitions as they
   occur.
3. If the process fails or is interrupted, the durable local outbox retains the
   last truthful transition and terminal or recoverable disposition.
4. A later projector can reconstruct the operation without scraping console
   text or guessing from missing output.

Acceptance:

- Human-readable logs are a projection; typed receipts and events are durable
  truth.
- Every failure names the last completed state and the unmet transition.
- Remote analytics availability cannot block the build.

## CUJ-37 - Portfolio Owner Reads X-Of-Y Build Intelligence

1. The build-intelligence projector consumes local outbox observations
   asynchronously.
2. It groups demand by product, platform, architecture, configuration,
   toolchain, channel, and dependency representation.
3. It reports requested, resolved, and provisioned X-of-Y coverage plus product
   hit rate, source/product ratio, stale and missing contexts, duration, and
   freshness posture.
4. The owner drills from a summary cell to its admitted resolution, build, and
   artifact receipts.

Acceptance:

- Requested, resolved, and provisioned are never collapsed into one success
  counter.
- Git supplies historical admission facts; the projection remains rebuildable.
- Analytics can lag without changing build correctness.

## CUJ-38 - Platform Owner Selects A Platform Manifest And OS Proof Suite

1. Vaporize derives the platform environment before prerequisite, resolution,
   and provision planning.
2. Policy selects the matching manifest and service implementations as data.
3. The platform-specific test suite proves discovery, process execution,
   resolution, failure, and receipt behavior on that OS.
4. The same logical service contract returns comparable typed results across
   supported platforms.

Acceptance:

- Service implementations do not hide different OS behavior behind compile-time
  conditional branches.
- Each supported OS has a separate test suite.
- All subprocess work uses CommonProcess.

## CUJ-39 - Package Author Declares One Temporal Dependency Request

1. A package author declares a logical dependency coordinate, its local and
   permitted remote locations, and a Calendar-Origin `from:` version.
2. The author may optionally permit source or product representation without
   encoding command configuration into the declaration. An admitted product
   record may identify an embedded payload or a depot locator; the depot is not
   a third representation or a dependency-selection route.
3. Vaporize derives debug/release, platform, architecture, toolchain, and release
   channel from the active command context.
4. The selected representation produces the same logical dependency identity
   and a context-specific receipt.

Acceptance:

- The declaration does not pin ordinary compatibility to an instantly stale
  hash.
- `Major.YYMM.DDHHR` compatibility remains inside the declared major.
- Local and permitted remote repository endpoints describe supply routes for
  the same dependency identity. A depot locator is payload data attached to the
  Git-selected admitted record, never a competing route or version authority.

## CUJ-40 - Existing User Receives Exact Legacy Behavior

1. A user launches Vaporize without enabling the SwiftPM library-product
   feature and supplies an existing command or manifest.
2. The CLI composes `CommonFeatureFlags`, activates the compiled/default OFF
   policy, and selects the legacy workflow service.
3. The unchanged service plans and executes the operation and emits its current
   receipt.
4. The CLI terminates without consulting a depot, probing a network, selecting
   a product carrier, or mutating resolution state for the experiment.

Acceptance:

- Golden proof covers command planning, arguments, process requests, exit
  behavior, manifest output, resolution behavior, and receipt bytes or an
  explicitly documented semantic normalization.
- The legacy workflow implementation is not edited to host the experiment.
- Rollback is policy-only: OFF selects legacy behavior on the next launch.

## CUJ-41 - Developer Runs The Library-Product Sibling Workflow

1. A developer explicitly enables the compiled-disabled feature for a
   library-only SwiftPM fixture.
2. `PolicyEvaluatorService` selects the library-product sibling before
   execution.
3. The sibling builds and tests the named library product without requiring a
   CLI-shaped product identity.
4. Vaporize emits a Schema Universal-owned typed receipt naming the workflow,
   product kind, actual platform context, and outcome, then terminates.

Acceptance:

- WarehouseKit audit proves the `CommonFeatureFlags` dependency,
  `PolicyEvaluatorService` injection, `ReleaseFlagSnapshot.compiledFeatures`,
  and `OverridableFeatureFlagService` construction obligations.
- The first proof names the carrier actually tested and makes no universal
  carrier claim.
- A carrier miss produces explicit source fallback or typed
  `ProvisioningRequired`; the depot remains optional.

## CUJ-42 - Product Owner Decides And Removes The Experiment

1. The Beads v0.0.3 feature graph has completed impact analysis, product
   document deltas, flagged sibling implementation, and the existing
   `feature-gated-cli-dependency-experiment` plan/run stages.
2. The analytics child produces typed cohort receipts before asking for a
   decision.
3. A human promotes or rejects the candidate from those receipts.
4. The cleanup child removes the temporary flag and losing branch, and closure
   validation proves the surviving unflagged behavior before the parent closes.

Acceptance:

- `parentId` and typed `blocks` edges make every readiness transition
  computable.
- `FR-VAPORIZE-BUILD-TEST-LIBRARY-ONLY-PRODUCT-2026-07-08` remains the mapped
  implementation-problem child rather than a duplicate.
- No decision occurs without analytics receipts, and no decision completes the
  feature while the flag or dead branch remains.

## Deferred CUJ - Assistant Proves Fleet Pkl-Backed Apple Project Build Parity

This journey blocks final internal v0.0.1 release.

1. Assistant receives a substrate-owned Apple app home currently backed by
   XcodeGen.
2. The app home exposes its project-generation truth through a Pkl-backed owned
   path rather than direct XcodeGen choreography.
3. Assistant runs the Vaporize build/install path.
4. Vaporize owns the transition from typed generation truth to buildable
   world-state and emits release evidence.

Current status:

- Blocked by
  `FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl`.
- Creative Selection v0.2 now has a generated `project.pkl` parity specimen and
  Vaporize can generate first-slice `.xcodeproj` world-state from it.
- This remains blocked for final internal release until fleet build parity and
  explicit XcodeGen quarantine disposition are proven.
- Existing XcodeGen surfaces remain historical compatibility, not the forward
  release path for our own apps.
- Shared workspace product-cache reuse may speed this journey once the fleet is
  known to be present in the maintained workspace, but CUJ-15 does not replace
  fleet parity proof.
