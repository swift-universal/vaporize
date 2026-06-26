# Vaporize Workstream Process Modernization Proposal

Date: 2026-06-26
Owner: Vaporize Workstream Modernization Steward
Component home: `private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli/`

## Trigger

The Git and Savepoint SCM audit initially used `xcrun swift package describe`
as the visible proof lane. The operator corrected that the workstream should
use Vaporize. The correction was valid: `vaporize.cli@wrkstrm-core.clia.sh` is
installed and all Git/Savepoint package test lanes passed through Vaporize.

## Captured Result

Vaporize proof lane was green for:

- `swift-git-cli`: 28 tests plus 1 foundation-models tool test.
- `savepoint.cli`: 11 tests.
- `savepoint.sd`: 7 tests.
- `savepoint-commit.digikoma.clia`: 11 tests.
- `savepoint-git-push.digikoma.clia`: 5 tests.
- `github-desktop-metadata-schemas`: 3 tests.
- `service-context-schemas`: 29 tests.

Native exception: `xcodebuild -list` remains the appropriate receipt for
proving a rehomed `.xcodeproj` loads until Vaporize wraps that exact project
load check as a first-class receipt.

## Findings

1. The installed executable name is `vaporize.cli@wrkstrm-core.clia.sh`.
   Workstream prose still sometimes says `vaporize@wrkstrm-core.cli`.

2. Installed help exposes `install`, `uninstall`, `build`, `test`, `run`,
   `pass`, `use`, `toolchain`, `setup`, `status`, `warehouse`,
   `validate-json`, `inspect-project-yml`, `inspect-target-features`,
   `compare-project-yml-pkl`, `import-project-yml`, `generate-project-yml`,
   `generate-xcodeproj`, `list-targets`, `list-schemes`, `release-doctor`,
   `inventory`, `domains`, `self-update`, and `graph`.

3. Current workstream formulas still cite `vaporize realize <typed-record-path>`.
   A component-home bead already exists for this mode, but the installed CLI
   does not expose it yet.

4. Capture doctrine now bans `jq` as a proof lane and direct `git` as assistant
   persistence. Vaporize process docs should reflect that without ambiguity.

5. `validate-json` has an existing bead for repeated `--path` behavior. Until
   fixed, process docs should require one invocation per path or a tested
   multi-path contract.

## Upgrade Proposal

### P0: Tool Reality Gate

Every Vaporize-owned workstream run starts with:

- `vaporize.cli@wrkstrm-core.clia.sh --version`
- `vaporize.cli@wrkstrm-core.clia.sh --help`
- current mode comparison against workflow formulas that cite Vaporize modes

Exit condition: stale mode names become component-home beads before any
implementation work is claimed.

### P0: Vaporize-First Proof Matrix

For Swift package work, the primary proof command is:

```sh
vaporize.cli@wrkstrm-core.clia.sh test --package-path <package> --configuration debug
```

Raw `swift` commands may remain subordinate diagnostics, but they should not be
the headline receipt for Vaporize-owned process work.

### P0: No jq / No Direct Git Process Contract

Replace proof recipes that use `jq` with:

- `vaporize validate-json --path <file>` for JSON syntax receipts
- generated Swift model decoding where typed conformance matters
- future typed-record-validator when it lands

Replace assistant persistence recipes that use direct `git` with:

- `savepoint.cli@kura-org.clia.sh emit ...`
- explicit blocked status when no approved savepoint/status surface exists

### P0: Kura World Seed-State Harness

Start the simulation proof lane by deriving Kura seed states from CUJs. The
seed-state harness should model the world a CUJ needs, not lead with database
engine concerns:

- `VaporizeKuraWorldSeedStateHarness` prepares isolated Kura world seed-state
  roots for tests.
- CUJs are the source records. A CUJ defines actor, intent, preconditions,
  actions, outcomes, tags, and metadata.
- The harness writes `cujs.json`, `kura-world.seed-state.json`, and
  `kura-world.seed-state.receipt.json`.
- The seed-state document contains one Kura world record per CUJ so tests can
  simulate product state from user journeys.
- The receipt names `storageFamily: kura` and does not expose Turso, libSQL, or
  database URL fields.

Implemented first slice:

- `tests/vaporize-test-support/KuraWorldSeedStateTestSupport.swift`
- `tests/cuj-21-kura-world-seed-state/VaporizeCUJ21KuraWorldSeedStateTests.swift`
- `Package.swift` target `VaporizeCUJ21KuraWorldSeedStateTests`

Exit condition: future integration with `kura@kura-org.sd` or Kura Sync Node is
explicitly gated and receipt-backed. The core abstraction remains CUJ-derived
world simulation.

### P1: Realize Mode Decision

Choose one:

- Implement `realize` as a real Vaporize mode accepting typed VaporwareUnit
  records and emitting plan plus receipt.
- Rename the workflow state away from installed-command language until the
  feature exists, preserving the existing bead as the forward implementation
  tracker.

Recommendation: implement `realize`, because the workstream doctrine already
depends on typed vaporware collapsing into world-state.

### P1: Receipt Standardization

Every proof mode should support a structured receipt path:

- `test`: package path, product/test targets, counts, elapsed time, toolchain,
  exit code, and package identity.
- `validate-json`: one receipt item per path.
- `list-targets` / `list-schemes`: target/scheme inventory plus source
  authority.
- `release-doctor`: existing release checks plus source paths.
- `kura-world-seed-state`: source CUJ count, seed record count, CUJ manifest
  path, seed-state document path, storage family, metadata, and created-at
  timestamp.

### P1: SCM Audit Recipe

For Git and Savepoint product lines, the process recipe is:

1. Run Vaporize tests for all SwiftPM packages in the product line.
2. Run Vaporize JSON validation for edited typed records and descriptors.
3. Run Vaporize inventory/list-targets where project/package topology changed.
4. Use native `xcodebuild -list` only as an explicitly named native authority
   exception until Vaporize owns an equivalent project-load receipt.
5. Persist with Savepoint per git boundary.

### P2: Workflow Formula Hygiene

Add a regular Vaporize release-doctor check that scans workflow formulas and
Vaporize docs for:

- stale executable names
- cited modes not present in installed help/source
- `jq` proof recipes
- direct `git` persistence recipes
- old domain names such as `source-control` where `scm` is canonical
- stale live-fixture expectations such as CUJ08 Concourse project.yml counts
  drifting behind the current project topology

## Decision Ask

Approve this process upgrade as the forward Vaporize workstream discipline:
Vaporize-first proof, installed-mode reality checks, no `jq`, no direct git
persistence, structured receipts, and explicit native-authority exceptions.

## Linked Records

- Workflow instance:
  `private/universal/substrate/collectives/spaces-universal/private/universal/kura-spaces/workflows/vaporware-modernization-workstream/v0.0.2/instances/vaporize-workstream-process-modernization-2026-06-26.workflow-instance.su.json`
- Component bead:
  `private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli/agenda/beads/FR-VAPORIZE-WORKSTREAM-PROCESS-MODERNIZATION-2026-06-26.beads-issue.json`
- Kura world seed-state harness bead:
  `private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli/agenda/beads/FR-VAPORIZE-KURA-WORLD-SEED-STATE-HARNESS-2026-06-26.beads-issue.json`
- Role manifest:
  `private/universal/substrate/roles/vaporize-workstream-modernization-steward/private/universal/identity/vaporize-workstream-modernization-steward.role-surface-manifest.json`
