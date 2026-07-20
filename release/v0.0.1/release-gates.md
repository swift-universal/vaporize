# Vaporize v0.0.1 - Release Gates

**Status:** release-prep draft; blocked pending fleet Pkl-backed Xcode world-state parity
**Updated:** 2026-07-20T03:00:00Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

## Current Verdict

**BLOCKED-FOR-INTERNAL-ESSENTIAL-RELEASE.**

The CUJ-derived test coverage contract now defines the required floor:
132 Swift test obligations plus 14 release evidence checks across 27 active CUJs.
The Vaporize package tests cover 196 executable Swift tests across 26 implemented
CUJ-specific SwiftPM bundles through Vaporize's owned `test` operation,
including the CUJ-16 `inspect-target-features` first slice and CUJ-17
`release-doctor` first slice, CUJ-18 `list-targets` first slice, and CUJ-19
workspace product-cache discovery first slice, plus the CUJ-20 `list-schemes`
first slice, CUJ-21 CUJ-state coverage gate, CUJ-22 SwiftPM CLI resource-bundle
install preservation, and CUJ-14 expected-pass/expected-fail coverage for typed
release identity plus framework/app/unit-test/package/shared-scheme graph
generation, plus CUJ-23 product proving-ground passports, including the Pkl
project-generation proving-ground passport, CUJ-25 saved portfolio audit
coverage, CUJ-26 canonical automated-proof ledger coverage, and CUJ-27
implementation-project coverage ledger. The evidence-ready
Swift YAML read bridge,
PklSwift-backed Pkl parity specimen, transitional YAML generation slice,
legacy-YAML-to-Pkl import slice, and major-feature test expansion are landed
and receipted. The first Pkl-backed `.xcodeproj` world-state generation slice is
also landed for Creative Selection v0.2. The shared Xcode workspace product
cache first slice is landed for cache-first app lookup and shared workspace
build invocation. The initial
schema-universal extraction for Vaporize evidence is also landed as
`vaporize-schemas v0.0.1`. The app/build-config source-of-truth correction is
now captured: app-facing Vaporize samples should compose with wrkstrm-core
`tool-registry`, `identifier`, and `app-artifacts` instead of inventing a
parallel config registry. The wrkstrm app-minimums requirement now has a
target-level first slice too: Vaporize inspects release-feature manifests,
generated xcconfigs, generated `ReleaseFeatures.swift`, and project wiring for
a given `project.yml` target before strong app claims are allowed. Vaporize now
also has a target-discovery first slice: `list-targets` reads AppleProjectSpec
from Pkl or legacy YAML and emits a typed receipt naming buildable candidates,
packages, schemes, and proof boundaries before build/cache routing work.
`list-targets` now also maps those buildable target facts to shared DerivedData
product-cache candidates and reports warm/missing status when the maintained
workspace cache pair is provided. Vaporize now also has a workspace
scheme-listing first slice: `list-schemes` delegates to
`xcodebuild -list -json -workspace` and receipts the live scheme list boundary
without claiming build/cache/fleet proof. The
package-local `vaporize.engineering.docc` catalog now carries the durable
engineering narrative for eventual `wrkstrm.com/engineering` publication,
including a canonical feature catalog that lists each major feature, user
problem, current surface, and proof boundary. The catalog also now names the
modularity and ownership rule: genuinely Swift Universal primitives belong in
`swift-universal`, Apple-bounded orchestration belongs in `wrkstrm-core`, and
Vaporize should grow by feature module rather than by accumulating command
logic in the CLI router. The release packet remains the linked proof corpus. The pre-code PRD review
session is now a hard future coding gate: Engineering, QA, and Marketing must
review the PRD before implementation starts. Vaporware modification request
discipline is also now a release gate: behavior-changing changes need a feature
flag or feature-status story, targetable tests, and release evidence before
release-ready status. Vaporware feature requests are product input; vaporware
modification requests are the controlled engineering execution unit. The
domain-specific name leaves room for future hardware or other material-domain
request families. Release doctor is now the key release-spine coherence gate:
it verifies that PRD, CUJs, gates, launch-review packet, provenance, CUJ
coverage, CUJ-state coverage, public-disclosure surfaces, feature catalog, and
engineering DocC agree before assistants trust the packet. The public brochure
and public changelog now exist as draft external disclosure surfaces, but they
are claim-limited by the marketing matrix and do not approve publication. Final
internal v0.0.1 release approval is still blocked by one hard capability gate:
substrate-owned Apple project generation still needs fleet build parity,
scheme/resource/package feature coverage, and explicit quarantine disposition
for any remaining XcodeGen surfaces.

## Human Review Policy

Automated proof can make a gate evidence-ready, but it cannot pass a gate. A
gate may only use `PASS`, `PASS-WITH-NOTE`, `APPROVED`, or
`APPROVED-WITH-NOTE` when the gate carries a gate-level human review record
with `reviewerKind=human`, `reviewerIdentityRef`, `humanReviewRef`, `signedAt`,
and `signedByAutomation=false`.

Until that record exists, machine-supported gates use
`EVIDENCE-READY-PENDING-HUMAN-REVIEW`. Release Doctor treats approved gate
statuses without human review as blocking failures.

## Gate Table

| Gate | Status | Evidence |
| --- | --- | --- |
| GATE-01 - PRD authored | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/prd.md` |
| GATE-02 - CUJs authored | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/cuj.md` |
| GATE-03 - Release gates authored | EVIDENCE-READY-PENDING-HUMAN-REVIEW | This file |
| GATE-04 - Launch-review packet authored | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/evidence/launch-review-packet.json` |
| GATE-05 - CUJ-derived package tests pass | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/evidence/cuj-test-coverage.json` requires 132 Swift test obligations plus 14 release evidence checks across 27 active CUJs. macOS package proofs use the explicit `test swift` or `test xcode` authority; non-macOS uses the collapsed `test` command. CUJ-01 proves the four-operation authority matrix, Linux-collapse policy, exact sibling retry, and removal of `--swift-source`. The dependency-free `tests/proving-grounds/core-command-authority` Swift Testing package passed through both authorities with retained receipts. The full suite plus focused CUJ runs remain the 196-test coverage model across 26 implemented CUJ-specific SwiftPM bundles. |
| GATE-06 - Independent toolchain selection and adjacent execution authority owned by Vaporize | EVIDENCE-READY-PENDING-HUMAN-REVIEW | Selection remains independent: the current host Swift proxy resolves to Vaporize and the Xcode provider reports `/Applications/Xcode-27.0.0-beta3.app/Contents/Developer`. Execution is owned separately by adjacent `swift` and `xcode` core-command authorities. The clean Swift Testing proving ground passed in 22.780 seconds through `default-swift` and 26.506 seconds through `xcrun-xcode-select`. The full graph diagnostic attributed 198.515 seconds to Xcode maintainer preparation and 341.875 seconds to its test subprocess before a nested negative-path receipt test failed; this is diagnostic evidence, not a generalized speed claim. |
| GATE-07 - CLI help reflects release surface | EVIDENCE-READY-PENDING-HUMAN-REVIEW | Fresh macOS help advertises adjacent `build/test/install/run swift|xcode` grammar, exact sibling retry behavior, and process-local `--developer-dir`; `--swift-source` is absent. The same source compiles the non-macOS discussion and option surface without Xcode authority or developer-directory vocabulary. Actual Linux binary execution remains a retained verification limit. |
| GATE-08 - CommonProcess use mode tested | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `VaporizeUseCommonProcessTests.swift` decodes valid spec JSON, loads a spec from disk, and rejects invalid executable refs. |
| GATE-09 - Vapor inventory tests pass | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `VaporizeCUJ07VaporInventoryTests` covers scanner status classification, legacy key handling, malformed JSON, path errors, and text/JSON rendering. |
| GATE-10 - JSON release packet validates | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `vaporize validate-json --path release/v0.0.1/evidence/launch-review-packet.json` passed. |
| GATE-11 - README matches release surface | EVIDENCE-READY-PENDING-HUMAN-REVIEW | README names the mirrored macOS core-command grammar, collapsed non-Xcode grammar, Swift tools 6.4, `use`, `toolchain-selection`, `validate-json`, Apple project migration commands, and shared Xcode workspace product-cache flags. Historical `x-craze-collapse-path` remains documented only as read-only compatibility. |
| GATE-12 - Open feature beads dispositioned | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/evidence/launch-review-blocker-disposition.json` classifies all 17 known follow-up beads. The release-blocking Pkl work is tracked once under GATE-14. |
| GATE-13 - Scoped release slice cleanliness | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/evidence/launch-review-blocker-disposition.json` records broad mono tree cleanliness as outside the scoped Vaporize launch-review slice. Scoped proof uses Release Doctor, JSON validation, package tests, and `git diff --check`. |
| GATE-14 - Pkl project generation for owned Apple surfaces | BLOCKED | Creative Selection v0.2 now proves first-slice Pkl-backed `.xcodeproj` world-state generation, and CUJ-14 now proves typed `releaseIdentity` projection plus macOS application, framework, tool, unit-test, target-dependency, local package, and shared-scheme generation boundaries. Final internal release still waits for fleet build parity and explicit quarantine disposition for any remaining XcodeGen-backed owned surfaces. |
| GATE-15 - Swift YAML read bridge | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `inspect-project-yml` parsed `private/apple/apps/concourse/project.yml` into Swift `AppleProjectSpec` data and emitted `release/v0.0.1/evidence/concourse-project-yml-inspection.receipt.json`; fleet audit parsed 155/155 discovered `project.yml` files and emitted `release/v0.0.1/evidence/project-yml-fleet-parse-audit.receipt.json`. This is read-only parity evidence, not release-unblocking generation or build proof. |
| GATE-16 - Old tool / Vaporize build comparison | EVIDENCE-READY-PENDING-HUMAN-REVIEW | Old XcodeGen script build and Vaporize app build both pass for Concourse after Vaporize derives the legacy `WRAPPER_NAME` from `project.yml`. Evidence: `release/v0.0.1/evidence/concourse-old-tool-vaporize-build-comparison.receipt.json`. This proves one specimen, not fleet build parity. |
| GATE-17 - Provenance artifact captured | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/evidence/vaporize-v0.0.1-provenance-artifact.json` and `.md` collect the receipts, validation commands, savepoint events, proven claims, unproven claims, and forward path for the Pkl migration slice. |
| GATE-18 - Concourse Pkl parity specimen | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `private/apple/apps/concourse/project.pkl` amends `Pkl/AppleProjectSpec.pkl`; `compare-project-yml-pkl` uses PklSwift and reports zero mismatches in `release/v0.0.1/evidence/concourse-project-yml-pkl-comparison.receipt.json`. This proves one Pkl parity specimen, not buildable project generation. |
| GATE-19 - Concourse Pkl transitional YAML generation | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `generate-project-yml` uses PklSwift to emit `release/v0.0.1/evidence/generated/concourse.apple-project-spec.generated.yml` plus `release/v0.0.1/evidence/concourse-pkl-project-yml-generation.receipt.json`; `release/v0.0.1/evidence/concourse-generated-yml-pkl-comparison.receipt.json` proves generated YAML still matches Pkl. The receipt explicitly says `.xcodeproj` world-state was not generated. |
| GATE-20 - Schema-universal extraction | EVIDENCE-READY-PENDING-HUMAN-REVIEW | Initial `vaporize-schemas v0.0.1` JSON schemas, fixtures, and fixture-backed Swift model package landed under `schema-universal/private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1`. The schema files and fixtures validate as JSON through Vaporize, and `schema-tighten audit` reports 0 safe-to-migrate hits for the slice. |
| GATE-21 - Legacy YAML to Pkl import | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `import-project-yml` generated `private/apple/apps/creative-selection-v0.2/project.pkl` from the v0.2 app's legacy `project.yml`; `creative-selection-v0.2-project-yml-pkl-import.receipt.json` records the import and `creative-selection-v0.2-project-yml-pkl-comparison.receipt.json` reports zero mismatches. The receipt explicitly says `.xcodeproj` world-state was not generated. |
| GATE-22 - Pkl Xcode project generation first slice | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `generate-xcodeproj` generated `/tmp/vaporize-creative-selection-v02-generated.xcodeproj` from `private/apple/apps/creative-selection-v0.2/project.pkl`; `creative-selection-v0.2-pkl-xcodeproj-generation.receipt.json` records `buildableWorldStateGenerated=true`, `xcodeProjectGenerated=true`, 1 target, and 4 source files. `vaporize-pkl-xcodeproj-tool-release-identity-modification.receipt.json` records the follow-on vaporware modification request for typed release identity, tool target products, expected-fail unsupported target coverage, and the expanded CUJ-14 expected-pass graph for framework/app/unit-test target dependencies, local package products, and shared schemes. This proves first-slice graph-generation semantics, not fleet build parity. |
| GATE-23 - Shared Xcode workspace product cache first slice | EVIDENCE-READY-PENDING-HUMAN-REVIEW | CUJ-15 covers product-cache option parsing, paired option validation, cache-first app lookup before local DerivedData, and Xcode build invocation through the shared workspace/DerivedData pair. This proves the invocation/cache-order slice, not automatic workspace scheme discovery or fleet cache warmth. |
| GATE-24 - Positioning and benchmark explainer | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/why-vaporize.md` explains why Vaporize exists, what problems it solves, how it compares to Swift, xcodebuild, and xcrun, current local benchmark numbers, build-space savings theory, user ergonomics, and the benchmark evidence still required before final release claims. |
| GATE-25 - Performance marketing claims | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/performance-marketing-claims.md` provides approved measured/behavioral/theoretical claim language, example copy, before/after examples, banned claims, and benchmark receipts required before stronger performance or disk-space claims are allowed. |
| GATE-26 - Product definition, user journeys, and choice argument | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/product-definition.md` defines Vaporize, primary users, product-level user journeys, why users choose it, when not to choose it, and build implications; PRD, CUJs, why explainer, claims, launch packet, coverage, and CUJ-09 tests reference the contract. |
| GATE-27 - Kura runtime sample series and Apple artifact ingestion | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `private/universal/substrate/collectives/wrkstrm/private/universal/kura-spaces/series/vaporize-runtime-samples/vaporize-runtime-samples.series.su.json` defines the queryable series. A backfilled CUJ-09 sample verifies SwiftPM coverage JSON, `.profraw`, `default.profdata`, build-output size, Debug product size, codecov artifact size, and Vaporize binary size through Vaporize's toolchain route. `release/v0.0.1/evidence/launch-review-blocker-disposition.json` keeps automatic sample emission, `.xcresult`/coverage/build-size artifact retention, and per-feature-flag size cohorts as strong-claim follow-ups; strong benchmark, disk-space, cache-warmth, and fleet-parity claims remain prohibited until durable receipts exist. |
| GATE-28 - wrkstrm-core app/build config composition | EVIDENCE-READY-PENDING-HUMAN-REVIEW | Existing build-config sources are identified and referenced in the release contract: `tool-registry@wrkstrm-core.cli discover-apps` emits Hello World-style `xcode-project` records, `identifier@wrkstrm-core.cli app describe` owns app variant names/paths, and `app-artifacts@wrkstrm-core.cli` owns bundle audits, install paths, Xcode build/export receipts, and flat `.app` artifacts. Vaporize integration remains a follow-up. |
| GATE-29 - wrkstrm app minimums inspection | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `inspect-target-features` inspects the target-level release-feature topology for Hello World Google: project configs, `configFiles` wiring, `Config/release-features.json`, generated conditional-compilation xcconfigs, generated `ReleaseFeatures.swift`, and `digikoma-release-features` provenance. Evidence: `release/v0.0.1/evidence/hello-world-google-target-features-inspection.receipt.json` and `VaporizeCUJ16TargetFeaturesTests`. Registry-backed fleet inspection remains a follow-up. |
| GATE-30 - Engineering DocC catalog | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `vaporize.engineering.docc/` defines the human engineering narrative for product policy, feature catalog, modularity and ownership boundaries, command/artifact architecture, project migration, release evidence, benchmark/size evidence, target-feature inspection, feature-scoped test lifecycle, and CUJ-state testing methodology. `feature-catalog.md` is the canonical human-readable feature list and explanation surface. `modularity-and-ownership-boundaries.md` requires genuinely Swift Universal primitives to live in `swift-universal`, Apple-bounded orchestration to live in `wrkstrm-core`, and Vaporize feature bodies to avoid accumulating in the CLI router. `cuj-state-testing-methodology.md` records why CUJ state, not database-first fixtures, is the architecture for vaporware spawn and modification proof. The future `wrkstrm.com/engineering` publication pipeline should project this catalog and link back to release receipts rather than inventing claims from prose. |
| GATE-31 - Pre-code PRD review session | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/prd-review-session.md` defines the mandatory Engineering, QA, and Marketing PRD review session before major coding starts. v0.0.1 records a backfilled `GO-WITH-NOTES` because this release-prep lane was already in flight; future major Vaporize coding slices do not get that exception. |
| GATE-32 - Vaporware modification request discipline | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `vaporize.engineering.docc/vaporware-modification-request-discipline.md` distinguishes vaporware feature requests as product input from vaporware modification requests as the controlled engineering execution unit. It leaves room for future hardware or other material-domain request families, and defines vaporware modification requests as release work: behavior-changing changes create or attach to an owning bead in the owning component or workstream home; create or attach to a feature flag, feature status record, or release-feature cohort; add or update targetable tests; run the smallest feature-scoped proof; update release evidence and schema fixtures when affected; and record explicit no-flag or no-bead exceptions. |
| GATE-33-release-doctor - Release doctor | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release-doctor --path private/apple/spm/vaporize@wrkstrm-core.cli` emits `release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json` and checks the release-spine agreement across required artifacts, public-disclosure surfaces including `public-brochure.html`, `user-manual.md`, and `evidence/audience-packet.su.json`, JSON evidence, PRD/CUJ/gate/catalog tokens, owning-bead discipline, launch-review references, launch-review/PRD/release-gate follow-up list coherence, launch-review blocker disposition, provenance inventory, CUJ coverage, and CUJ-state coverage. A pass proves spine coherence, not final release approval. |
| GATE-34-project-target-discovery - Project target discovery | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `list-targets --pkl-path private/apple/apps/creative-selection-v0.2/project.pkl --format json --receipt-path release/v0.0.1/evidence/creative-selection-v0.2-list-targets.receipt.json` emits a `vaporize-project-target-discovery` receipt with one buildable Creative Selection v0.2 target, candidate scheme names, package count, source paths, and boundaries. This proves target discovery from AppleProjectSpec, not build/install/generation, cache warming, or `.xcworkspace` graph membership discovery. |
| GATE-35-workspace-product-cache-discovery - Workspace product-cache discovery | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `list-targets --pkl-path private/apple/apps/creative-selection-v0.2/project.pkl --xcode-product-cache-workspace /tmp/vaporize-maintained-workspace/Huge.xcworkspace --xcode-product-cache-derived-data-path /tmp/vaporize-maintained-workspace/DerivedData --format json --receipt-path release/v0.0.1/evidence/creative-selection-v0.2-workspace-cache-discovery.receipt.json` emits one expected shared DerivedData product candidate with missing status. This proves candidate-path and warm/missing discovery from target facts, not `.xcworkspace` graph parsing, cache warming, fleet cache coverage, or disk-savings measurement. |
| GATE-36-xcode-workspace-scheme-listing - Xcode workspace scheme listing | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `list-schemes --xcode-workspace <workspace.xcworkspace>` routes `xcodebuild -list -json -workspace` through Vaporize/CommonProcess and the CUJ-20 bundle covers CLI parsing, xcodebuild arguments, JSON parsing, input validation, and receipt boundaries. The first live `rismay-substrate.xcworkspace` probe exceeded the interactive investigation window and was stopped without a receipt, so this proves the command/parser/receipt slice, not large-workspace runtime, cache warmth, product paths, or fleet coverage. |
| GATE-37-cuj-state-coverage - CUJ-state coverage | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `release/v0.0.1/evidence/cuj-state-coverage.json` names every required CUJ-state id for the SCM product-suite fixture and attaches a proof entry from `VaporizeCUJ21CUJStateTests`. Release doctor checks coverage status, required ids, proof floor, uncovered ids, unknown ids, and duplicate proof ids. This proves journey-derived state coverage, not Kura adapter readiness or public release approval. |
| GATE-38-public-disclosure-surfaces - Public brochure and changelog | EVIDENCE-READY-PENDING-HUMAN-REVIEW | Every brochure must have an audience packet and user manual. Carrie CMO (`cmo-chief-marketing-officer@wrkstrm.jobs.org`) owns the consumer-facing publication gate for public-disclosure surfaces; wrkstrm-core owns the Vaporize implementation evidence and release-doctor mechanics. `release/v0.0.1/public-brochure.html`, `release/v0.0.1/evidence/audience-packet.su.json`, `release/v0.0.1/user-manual.md`, `release/v0.0.1/public-brochure.md`, and `release/v0.0.1/public-changelog.md` define the external public disclosure draft surface. Release doctor requires the marketing site, audience packet, user manual, Markdown companion, changelog, chief-office owner reference, and launch-review references. This proves public-disclosure packet shape, not publication approval, public launch readiness, Sparkle appcast/signing readiness, or stronger performance/disk-space claims. |
| GATE-39-resource-cli-install - SwiftPM CLI resource-bundle installs | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `vaporize.engineering.docc/swiftpm-cli-resource-bundle-installs.md` documents the install policy. `VaporizeCUJ22ResourceCLIInstallTests` proves the release-facing simulation proving ground: scenario coverage fails when a required receipt is missing, and Vaporize carries processed text, copied directory, decoded JSON, byte-count, and stale-reinstall resource scenarios from SwiftPM's `--show-bin-path` products directory into `~/.swiftpm/bin`. CUJ-01 retains the lower-level regression proof for the raw `experimental-install` gap. Product version/build information is recorded in `~/.swiftpm/bin/<product>.metadata/Info.plist`. This proves resource-bearing CLI install behavior, not app bundle packaging, `Bundle.main.infoDictionary` metadata, Sparkle appcast generation, update signing, or public update delivery. |
| GATE-40-product-proving-grounds - Product proving-ground passports | EVIDENCE-READY-PENDING-HUMAN-REVIEW | `vaporize.engineering.docc/product-proving-grounds.md` defines product proving-ground tracks and product-class defaults. `VaporizeCUJ23ProductProvingGroundTests` proves a Vaporize CLI passport, a Pkl project-generation proving-ground passport, incomplete-passport failure for missing tracks, missing receipts, and missing targetable tests, plus reusable defaults for CLI, app, library, workflow, generator, assistant, and site products. This proves adoption evidence shape, not product-specific release approval. |

## Open Follow-Up Beads

- `FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl`
- `FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS`
- `FR-VAPORIZE-REALIZE-typed-vaporware-unit`
- `FR-VAPORIZE-TOOL-CALL-OBSERVABILITY`
- `FR-VAPORIZE-DRIFT-CATCH-retire-craze-canonical-language`
- `FR-VAPORIZE-PRODUCT-RELEASE-DIR-RENAME-MODE`
- `FR-VAPORIZE-XCODE-WORKSPACE-GRAPH-MEMBERSHIP-DISCOVERY`
- `FR-VAPORIZE-XCODE-WORKSPACE-SCHEME-LISTING-RUNTIME-SAMPLES`
- `FR-VAPORIZE-RUNTIME-SAMPLE-SERIES-APPLE-ARTIFACT-INGESTION`
- `FR-VAPORIZE-WRKSTRM-CORE-BUILD-CONFIG-COMPOSITION`
- `FR-VAPORIZE-WRKSTRM-APP-MINIMUMS-INSPECTION`
- `FR-VAPORIZE-ENGINEERING-DOCC-PUBLICATION-PIPELINE`
- `FR-VAPORIZE-PRD-REVIEW-SESSION-BEFORE-CODING`
- `FR-VAPORIZE-VAPORWARE-SCAFFOLD-FEATURE-REQUESTS`
- `FR-VAPORIZE-BUDDY-HEARTBEAT-AND-BUILD-WATCH`
- `FR-VAPORIZE-PUBLIC-DOCUMENTATION-ARTIFACT-MAINTENANCE-2026-07-04`
- `FR-CMO-CONSUMER-FACING-PUBLIC-DISCLOSURE-GATE-OWNERSHIP-2026-07-04`

## Release Review Questions

- Which substrate-owned XcodeGen-backed Apple surfaces must migrate to Pkl
  before internal v0.0.1 can release?
- Is `use --common-process-spec` enough for the first CommonProcess-style
  invocation surface, or must a higher-level typed wrapper land before release?
- Should README drift be fixed in this release branch before launch review, or
  carried as a blocking release-docs bead?
- Should the transitional `generate-project-yml` bridge remain as migration
  evidence after the owned `.xcodeproj` generator exists, or be quarantined as
  a temporary parity tool?
- Should the transitional `import-project-yml` bridge remain available after
  the owned `.xcodeproj` generator exists, or become an explicit legacy-only
  migration utility?
- Should Vaporize preserve this legacy `WRAPPER_NAME` compatibility only until
  Pkl generation lands, or should it remain as a permanent compatibility bridge
  for quarantined XcodeGen projects?
- Which project feature slice should follow expanded `generate-xcodeproj`
  graph generation: generated project build parity for one legacy app,
  remaining XcodeGen quarantine, or broader fleet build parity?
- Should automatic shared workspace cache discovery extend the facts emitted by
  `list-targets`, compose with `list-schemes`, or grow a dedicated workspace
  product query mode?
- Which benchmark fixture should become the canonical release benchmark:
  Concourse, Creative Selection v0.2, or the maintained huge workspace?
- Which performance claim should get the first dedicated benchmark receipt:
  warm cache install time, cold cache miss time, or DerivedData disk savings?
- Does each new Vaporize feature trace to `product-definition.md` before
  implementation, tests, and release claims are accepted?
- Should `vaporize toolchain-selection`, app build/install, and shared-cache modes grow a
  `--runtime-sample-series` flag that writes Kura JSONL samples and copies or
  references SwiftPM coverage, xUnit, `.xcresult`, build log, diagnostic, and
  DerivedData/product artifacts?
- How should Vaporize encode per-feature-flag build-size cohorts so app teams
  can compare product, binary, bundle, and artifact deltas the way mature app
  teams track feature-flag cost?
- Should the first app-facing runtime sample use Hello World Google as the
  canonical fixture because it already has `xcode-project` registry records,
  Debug/Dogfood/TestFlight/Release configs, generated xcconfig wiring, and
  release-feature source material?
- Should registry-backed app-minimums inspection extend `inspect-target-features`,
  become a standalone `app-minimums` command, or fold into future `list-targets`
  / app-runtime-sample emission?
