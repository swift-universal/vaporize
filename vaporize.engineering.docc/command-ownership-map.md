@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Command Ownership Map")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Command Ownership Map

This page classifies the complete public surface emitted by the Vaporize man
page. It is both a description of the current command set and the ownership
constraint for future command work.

A command name states a product responsibility. The lower-level program used
to implement that responsibility is not itself the responsibility. A missing
owner is an explicit command-design gap; it is not permission to add unrelated
behavior to the nearest existing command.

## Ownership Rules

1. Selection changes or reports an active selection. It does not acquire,
   update, execute, or generally inspect a toolchain.
2. Execution belongs to an operation that describes why the process runs:
   build, test, run, pass, or use.
3. Artifact lifecycle commands own installation and removal of produced
   artifacts, not installation of development toolchains.
4. Inspection and audit commands report world-state without mutating it.
5. Transformation commands create or migrate project world-state and name the
   representation they produce.
6. Platform-specific public choices are compiled only on the platform that can
   implement them. Unsupported choices are absent, not runtime stubs.

## Canonical Graph Artifact

The machine-readable ownership source is
`architecture/vaporize.public-surface.dag.json`. Its canonical home and suffix
follow the spawn-vaporware public-surface contract. It conforms to
schema-universal's `DagModel` v0.0.1 contract and is rendered through the
wrkstrm-components `dag-viz` family:

```sh
dag-viz-tui@wrkstrm-components.cli --plain dag-model architecture/vaporize.public-surface.dag.json
```

The Markdown tables explain the ontology; they do not own it. Product tests
compare every `VaporizeCLI.Mode` raw value with the graph's `mode.*` nodes,
so a public mode cannot be added or removed without updating the graph. A
second verifier compares every long option in the checked-in generated man
page with the option ownership map below. Shared parser flags remain mapped
parameters rather than being flattened into peer command nodes.

## Complete Mode Map

| Responsibility | Modes from the man page | Ownership |
| --- | --- | --- |
| Artifact lifecycle | `install`, `uninstall`, `build`, `test`, `run` | Build, install, remove, test, or launch CLI and app artifacts. App test uses a declared Xcode project/workspace and shared scheme; it never requires an app `Package.swift`. |
| Controlled execution | `pass`, `use` | Run forwarded arguments or a typed CommonProcess specification and emit the corresponding evidence. |
| Toolchain selection | `toolchain-selection` | Select or report the active Swift selection; on macOS, select or report the active Xcode developer directory. |
| Host provisioning | `setup` | Download a named Xcode component. This is provisioning, not Xcode selection. |
| Vaporware state | `status`, `warehouse` | Observe or store typed vaporware state. |
| Validation | `validate-json`, `validate-json-schema` | Validate data or a schema fixture and report the result. |
| Project inspection | `inspect-project-yml`, `inspect-target-features`, `compare-project-yml-pkl`, `list-targets`, `list-schemes` | Read and compare project world-state without migrating it. |
| Project transformation | `import-project-yml`, `upgrade-project-yml-to-pkl`, `generate-project-yml`, `generate-xcodeproj`, `generate-sparkle-config` | Import, upgrade, or generate a named project representation or source artifact. |
| Release and coverage audit | `release-doctor`, `cuj-audit` | Audit release or CUJ proof state. |
| Portfolio observation | `inventory`, `version-status`, `domains`, `fleet-status`, `graph` | Report owned project, source-version, domain, installed-tool, or package-graph state. |
| Product maintenance | `self-update`, `maintainer-dependencies` | Update Vaporize itself or materialize its maintainer-selected SwiftPM dependency authority. |
| Compatibility debt | `cli`, `app` | Deprecated spellings retained by the existing artifact lifecycle parser. They are not command-family precedents. |

## Toolchain Selection Contract

The Vaporize public grammar is macOS-only:

```text
vaporize toolchain-selection xcode -- select [xcode-select-options]  # macOS only
```

Temper owns Swift toolchain selection and lifecycle. Vaporize resolves the
already selected `swift` from `PATH`; it does not embed a Swift selection
provider or proxy executable names into a toolchain manager.

The Xcode provider is compiled only on macOS and delegates selection state to
`/usr/bin/xcode-select`. Arbitrary `xcrun` execution, Xcode version inspection,
and Swift or DocC execution are not owned by `toolchain-selection`.

Use the existing execution owners instead:

- `install`, `build`, `test`, and `run` own artifact-aware execution. On
  macOS, each requires the adjacent `swift` or `xcode` execution authority.
  On hosts without Xcode, the same command collapses to its Swift authority
  and the authority token is absent.
- `pass` owns untyped forwarded execution.
- `use` owns typed CommonProcess execution.

Swift toolchain acquisition/lifecycle and generic Xcode tool inspection do not
yet have dedicated Vaporize commands. They remain named ownership gaps rather
than hidden selection behaviors.

## Complete Option Map

The current parser is flat, so ArgumentParser exposes every option beside every
mode in one manual page. The ownership below defines which family is allowed to
interpret each option; it also provides the split points for future typed
subcommands and per-command man pages.

| Option | Owner |
| --- | --- |
| `--version` | Vaporize product identity. |
| `--artifact`, `--package-path`, `--product`, `--product-version`, `--product-build`, `--product-build-sha`, `--product-build-date`, `--su-feed-url`, `--su-public-ed-key`, `--app-bundle-name`, `--configuration`, `--destination`, `--force`, `--skip-build`, `--skip-install`, `--launch` | Artifact lifecycle. |
| `--xcode-project`, `--xcode-workspace`, `--scheme`, `--derived-data-path`, `--xcode-product-cache-workspace`, `--xcode-product-cache-derived-data-path`, `--xcode-destination`, `--xcode-sdk`, `--xcode-result-bundle-path`, `--xcode-build-setting` | Apple artifact build/test and workspace inspection where explicitly documented. |
| `--target` | Target feature inspection and Sparkle configuration generation. |
| `--analyze`, `--receipt-path` | Evidence emitted by the operation that owns the invocation. |
| `--report-path`, `--proof-ledger-path`, `--project-ledger-path`, `--project-ledger-csv-path` | CUJ audit evidence. |
| `--working-directory` | `pass`. |
| `--common-process-spec` | `use`. |
| `--developer-dir` | macOS Apple build/test execution. It does not choose the globally selected Xcode developer directory. |
| `--xcode-component` | `setup`. |
| `--path` | Status, warehouse, inventory, source-version status, CUJ audit, validation, inspection, comparison, import, and target discovery as enumerated by the option help. |
| `--schema`, `--fixture`, `--expect` | JSON Schema validation. |
| `--pkl-path`, `--pkl-schema-path`, `--output-path`, `--output`, `--apply` | Project import, upgrade, and generation. `test xcode --artifact app` also accepts `--pkl-path` as the source-root authority for a generated Xcode project. |
| `--format` | Typed rendering for the observation, inspection, audit, and generation modes enumerated by the option help. |
| `--bin-dir` | `fleet-status`. |
| `--domain` | Artifact lifecycle domain routing. |
| `--tools-collection` | `domains`. |
| forwarded arguments after `--` | `test`, `run`, `pass`, and `toolchain-selection`; each owner validates its own nested grammar. |
| `-h`, `--help` | Root command discovery generated by ArgumentParser. |

## Manual Architecture Constraint

The generated manual currently reflects one flat `mode` argument and a shared
option namespace. The ownership map does not pretend that this parser already
provides type-level isolation. It defines the required behavior now and the
target decomposition later: real ArgumentParser subcommands, family-local
options, and one generated man page per command family.

The manual generator also emits a synthetic `help` subcommand entry even though
the live Vaporize parser is a mode dispatcher and has no `help` mode. The
checked-in generator removes the false required `subcommand` synopsis operand;
the remaining synthetic help annotation is generator metadata, not a public
Vaporize responsibility.
