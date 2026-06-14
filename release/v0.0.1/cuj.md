# Vaporize v0.0.1 - Critical User Journeys

**Status:** release-prep draft; blocked pending fleet Pkl project-generation parity
**Updated:** 2026-06-14T02:29:38Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Product-Level User Journey Map

`release/v0.0.1/product-definition.md` defines the product-level journeys that
shape this CUJ set. Each active CUJ is a targetable release proof for at least
one product-level journey.

| Product-level journey | CUJ proof |
| --- | --- |
| Assistant builds, installs, or runs SwiftPM CLI/app software without composing shell choreography | CUJ-01, CUJ-02 |
| Assistant validates release JSON without direct `jq` | CUJ-06 |
| Assistant uses Xcode-selected Swift without direct `xcrun` | CUJ-05 |
| Assistant emits receipts for CommonProcess command execution | CUJ-03, CUJ-04 |
| Assistant inventories vaporware state from substrate records | CUJ-07 |
| Assistant migrates Apple project generation from legacy `project.yml` toward Pkl-backed truth with receipts at every boundary | CUJ-08, CUJ-10, CUJ-11, CUJ-13, CUJ-14 |
| Assistant reuses a warm Xcode workspace product cache instead of rebuilding locally when the shared product already exists | CUJ-15 |
| Release reviewer evaluates product definition, PRD review session, vaporware modification request discipline, user journeys, choice argument, evidence, gates, and blockers without relying on chat memory | CUJ-09 |

## CUJ-01 - Assistant Builds And Installs A SwiftPM CLI

1. Assistant receives a concrete SwiftPM package path and product name.
2. Assistant runs `vaporize build --artifact cli --package-path <package> --product <product>`.
3. Vaporize builds the product in the requested configuration.
4. Unless `--skip-install` is present, Vaporize installs the CLI through the
   owned Swift package install lane.
5. Assistant reports the command, configuration, and result.

Success:

- The assistant does not hand-compose `swift build` plus install commands.
- The build/install route is repeatable and uses one Vaporize invocation chain.

Failure truth:

- If the package path or product is missing, the assistant records the missing
  typed input and does not invent a product by grepping broad directories.

## CUJ-02 - Assistant Builds And Launches A Mac App

1. Assistant receives a Mac app package or project home.
2. Assistant runs `vaporize install --artifact app` with the package path,
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

## CUJ-05 - Assistant Uses Xcode-Selected Swift Without Direct xcrun

1. Assistant needs the Xcode-selected Swift toolchain because bare `swift` is not
   the required toolchain.
2. Assistant runs `vaporize toolchain -- swift <args>`.
3. Vaporize invokes `xcrun swift <args>` internally.
4. Vaporize preserves stdout, stderr, and exit semantics.
5. Vaporize can emit a `vaporize-toolchain` receipt when requested.

Success:

- The assistant does not call `xcrun` directly.
- Unsupported Xcode tools fail at Vaporize's parser boundary instead of turning
  `toolchain` into a general bypass for restricted native tools.

## CUJ-06 - Assistant Validates Release Packet JSON Without jq

1. Assistant creates or updates a release packet JSON file.
2. Assistant runs `vaporize validate-json --path <packet.json>`.
3. Vaporize parses the file with Foundation.
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

## CUJ-14 - Assistant Generates First-Slice Xcode Project World-State From Pkl

1. Assistant has an AppleProjectSpec Pkl specimen for a substrate-owned macOS
   application target.
2. Assistant runs
   `vaporize generate-xcodeproj --pkl-path <project.pkl> --output-path <generated.xcodeproj> --receipt-path <receipt>`.
3. Vaporize evaluates the Pkl record through PklSwift.
4. Vaporize renders deterministic `.xcodeproj` package world-state, including
   `project.pbxproj` and `project.xcworkspace/contents.xcworkspacedata`.
5. Vaporize emits a `vaporize-pkl-xcodeproj-generation` receipt.

Success:

- The generated `.xcodeproj` exists on disk with project, target, source phase,
  settings, product reference, and post-build script entries.
- The receipt explicitly records that buildable world-state and Xcode project
  generation were performed.
- Source paths are resolved from the Pkl file's project home, not from the
  chosen output directory.
- The renderer is deterministic for the same evaluated spec and source tree.

Failure truth:

- Missing non-optional source paths fail the generation with the target name and
  missing source path.
- This first slice supports macOS application targets. It does not yet prove
  fleet build parity, scheme generation, all XcodeGen feature parity, or final
  internal release readiness.

## CUJ-15 - Assistant Reuses A Warm Xcode Workspace Product Cache

1. Assistant knows the target app also exists in a large Xcode workspace that
   is kept warm by regular builds.
2. Assistant runs `vaporize install --artifact app` with the normal app
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
| CUJ-05 | FR-010 | 6 |
| CUJ-06 | FR-011 | 2 |
| CUJ-07 | FR-007, FR-008 | 10 |
| CUJ-08 | FR-015 | 5 |
| CUJ-09 | FR-012, FR-013, FR-014, FR-022, FR-025, FR-026 | 0 Swift tests; 7 release evidence checks |
| CUJ-10 | FR-016 | 4 |
| CUJ-11 | FR-017 | 3 |
| CUJ-12 | FR-009 | 1 |
| CUJ-13 | FR-018 | 4 |
| CUJ-14 | FR-020 | 3 |
| CUJ-15 | FR-003, FR-021 | 4 |
| CUJ-16 | FR-023, FR-024 | 5 Swift tests; 1 release evidence check |

Current active-CUJ requirement:

- Required Swift test obligations: 69
- Required release evidence checks: 8
- Required targetable test obligations: 77
- Current executable Swift tests: 87 across 16 implemented CUJ-specific SwiftPM
  bundles
- Coverage artifact:
  `release/v0.0.1/evidence/cuj-test-coverage.json`

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
- This remains blocked for final internal release until fleet build parity,
  scheme/resource/package feature coverage, and explicit XcodeGen quarantine
  disposition are proven.
- Existing XcodeGen surfaces remain historical compatibility, not the forward
  release path for our own apps.
- Shared workspace product-cache reuse may speed this journey once the fleet is
  known to be present in the maintained workspace, but CUJ-15 does not replace
  fleet parity proof.

## Deferred CUJ - Assistant Discovers Targets Through Vaporize

This journey is important but not v0.0.1-green yet.

1. Assistant receives a directory and desired artifact.
2. Assistant runs `vaporize list-targets --package-path <dir>`.
3. Vaporize emits a typed target discovery receipt.
4. Assistant builds or installs from that receipt.

Current status:

- Deferred to
  `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`.
