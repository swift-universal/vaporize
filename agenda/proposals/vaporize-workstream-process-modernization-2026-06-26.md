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

### P0: Turso-Like Database Harness Setup

Start the database proof lane with deterministic libSQL-style fixtures before
adding networked Turso execution:

- `VaporizeDatabaseTestHarness` prepares isolated local database fixture roots.
- Local storage writes a `file://` database URL and creates an empty
  `.libsql` file for tests that need a concrete database path.
- Remote storage records a `libsql://` Turso-style database URL plus the auth
  token environment-variable name, but default tests do not touch the network.
- Every prepared harness writes `migrations.sql`, `seed.sql`, and
  `database-harness-receipt.json` with migration counts, seed counts, storage
  mode, network requirement, metadata, and creation timestamp.

Implemented first slice:

- `tests/vaporize-test-support/DatabaseHarnessTestSupport.swift`
- `tests/cuj-21-database-harness/VaporizeCUJ21DatabaseHarnessTests.swift`
- `Package.swift` target `VaporizeCUJ21DatabaseHarnessTests`

Exit condition: networked Turso tests are opt-in behind explicit environment
configuration and emit structured receipts; default CI/test runs remain
network-free.

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
- `database-harness`: storage mode, local/remote URL, migration script path,
  seed script path, migration count, seed count, network requirement, metadata,
  and created-at timestamp.

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
- Database harness bead:
  `private/universal/substrate/collectives/wrkstrm-core/private/apple/spm/vaporize@wrkstrm-core.cli/agenda/beads/FR-VAPORIZE-TURSO-LIKE-DATABASE-TEST-HARNESS-2026-06-26.beads-issue.json`
- Role manifest:
  `private/universal/substrate/roles/vaporize-workstream-modernization-steward/private/universal/identity/vaporize-workstream-modernization-steward.role-surface-manifest.json`
