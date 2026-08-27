@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Windows Platform Upgrade Process")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Windows Platform Upgrade Process

Windows platform work advances in small, evidenced lifecycle slices.

The objective is not to make an app appear to build once. The objective is to
establish a repeatable Windows application path whose authority, inputs,
outputs, and limitations are all explicit. A platform or toolchain is not
called upgraded until the relevant gate has a receipt or focused test result.

The owning maintenance record is
`beads/fr-vaporize-windows-platform-upgrade-discipline-2026-08-21.beads-issue.su.json`.

## Authority Boundary

Vaporize intentionally uses two Windows authorities:

- `swift-win` owns raw Swift and `Package.swift` products such as CLI and TUI
  executables.
- `wcode` owns Windows application lifecycle work: build, run, installation,
  packaging, resource staging, Visual Studio initialization, and any other
  project-specific tooling.

`swift-win` is not a cheaper spelling of WCode. Passing `--artifact app` to it
fails before work begins and names the matching `wcode` command. Conversely,
WCode refuses CLI and TUI artifacts and points back to `swift-win`. These are
artifact contracts, not toolchain retry lanes.

For a SwiftPM-shaped application, WCode delegates compilation to the selected
Swift toolchain and owns the surrounding application lifecycle. The package's
`project.pkl` declares portable application resources against the canonical
project-definition module. WCode evaluates that record through PklSwift and
materializes it through typed Swift services. PowerShell is not a build,
resource, installation, or launch authority.

Selecting the explicit `wcode` authority is also the feature gate. Existing
`swift-win` and Xcode commands never enter this lifecycle implicitly.

## Lifecycle Contract

The public Windows app surface is:

```text
vaporize build wcode --artifact app [options]
vaporize run wcode --artifact app [options] [-- product-arguments]
vaporize install wcode --artifact app [options]
```

The canonical lifecycle input is `--pkl-path <project.pkl>`. When omitted,
WCode resolves `<package-path>/project.pkl`. The selected target exposes a
first-class `resources` collection with package-relative sources and
resource-root-relative destinations.

| Environment value | Meaning |
| --- | --- |
| `WCODE_OPERATION` | `build`, `run`, or `install`. |
| `WCODE_PACKAGE_PATH`, `WCODE_PRODUCT`, `WCODE_CONFIGURATION`, `WCODE_ARTIFACT` | The selected app identity. |
| `WCODE_DESTINATION`, `WCODE_FORCE_REINSTALL`, `WCODE_SKIP_BUILD`, `WCODE_SKIP_INSTALL`, `WCODE_LAUNCH` | The requested lifecycle controls. Boolean values are `1` or `0`. |
| `WCODE_ARGUMENTS_JSON` | JSON array of product arguments passed after `--`. |
| `WCODE_RESOURCE_ROOT` | The published root containing the selected target's Pkl-declared application resources. |

These values are typed lifecycle composition inputs, not an arbitrary callback
surface. A missing capability fails closed and opens or updates the owning
feature Bead. It never falls through to a `.ps1` file.

Callers may add application environment values with `--wcode-environment`, but
names beginning with `WCODE_` are reserved for the lifecycle service and are
rejected rather than allowed to spoof receipt state.

`Package.swift` remains authoritative for source compilation, dependencies,
and resources accessed through `Bundle.module`. Pkl staging does not manufacture
a compile-time `Bundle.module` accessor. Installation never sweeps the shared
SwiftPM products directory: every required `.dll`, `.bundle`, or `.resources`
sibling must be admitted by exact safe filename with a repeated
`--wcode-runtime-artifact` option and is recorded in the lifecycle receipt.

## Deliberate Upgrade Gates

Each gate is completed before the next starts. A failure is evidence: capture
the command, output, toolchain version, and receipt, then repair the owning
layer rather than routing around it.

1. **Preflight the toolchain and Vaporize package.** Record `swift --version`,
   resolve every local SwiftPM dependency, run `swift package dump-package`, and
   build/test Vaporize's focused Windows authority coverage. The current
   observed blocker is a missing local `swift-log` checkout; restore that
   dependency before treating a Vaporize build/test failure as a Windows app
   failure.
2. **Prove the authority boundary.** Confirm that `swift-win --artifact app`
   gives the WCode next-step command, that WCode rejects CLI/TUI artifacts, and
   that the focused CUJ-01 tests pass. This guards against a silent fallback to
   the wrong build system.
3. **Prove the project declaration.** Evaluate the pilot's `project.pkl`,
   select the intended target and platform, and retain its digest plus resource
   plan. Required missing inputs, path escape, collisions, and unsupported
   processing stop the lane before a build result is published.
4. **Build one pilot app with WCode.** Begin with the smallest Windows app and
   record the package path, target, product, configuration, resource root,
   backend environment, and resulting executable location.
5. **Run the same pilot through WCode.** Pass product arguments after `--` and
   preserve the receipt. A successful build is not a run proof; validate that
   the expected backend, runtime dependencies, and staged resources are selected.
6. **Install through WCode.** Validate that the selected executable, explicitly
   admitted runtime artifacts, and Pkl resource root arrive beneath the
   per-user `%LOCALAPPDATA%/Programs` root. Reinstall and launch flags remain
   explicit typed inputs; `--force` cannot replace an arbitrary directory.
7. **Expand only after the pilot is repeatable.** Add another app or Windows
   platform target one at a time. Re-run the preceding successful gates before
   changing the toolchain, backend, packaging format, or deployment location.

The first app is a proving ground, not fleet parity. A green result for one
backend, SDK, or package shape does not certify the others.

## Evidence and Stop Conditions

Use `--receipt-path` and `--analyze` for lifecycle commands when receipts are
available in the workstream. Keep the Pkl digest, selected target, resource
plan, command line, toolchain version, backend environment, installed location,
and focused-test result together in the app's upgrade record.

Stop and open or update the owning bead when any of these occurs:

- a raw Swift command is asked to install, run, or package an app;
- the canonical Pkl record is absent, selects no target, or declares an
  unsupported resource operation;
- a resource source or destination escapes its allowed root or collides with
  another declaration;
- a product or runtime artifact is not one safe Windows filename component;
- an install destination is not a strict descendant of the admitted per-user
  Programs root;
- a caller attempts to override a reserved `WCODE_` environment value;
- a build succeeds but the app cannot run under the selected backend;
- an install mutates an existing app without an explicit reinstall policy;
- a missing local dependency prevents the Vaporize contract from being built or
  tested; or
- a new SDK/toolchain changes the evidence outcome from the last completed
  gate.

Windows WCode app testing is intentionally still a named gap: `test wcode
--artifact app` fails with an explicit message rather than reaching Apple test
machinery. Add that contract only after build, run, and install have stable
pilot evidence.

## Example Pilot Sequence

```text
# 0. Establish the source/toolchain baseline.
swift --version
swift package dump-package
swift test --filter VaporizeCUJ01SwiftPMCLITests

# 1. Build and run the chosen Windows app through its app authority.
vaporize build wcode --artifact app --package-path <package> --pkl-path <package>/project.pkl --product <app-product> --configuration debug --wcode-environment SWIFTUUI_DEFAULT_BACKEND=WinUIBackend --analyze --receipt-path <build-receipt.json>
vaporize run wcode --artifact app --package-path <package> --pkl-path <package>/project.pkl --product <app-product> --configuration debug --analyze --receipt-path <run-receipt.json> -- <app-arguments>

# 2. Install the exact executable, explicitly named SwiftPM runtime artifacts,
#    and staged Pkl resources beneath %LOCALAPPDATA%/Programs.
vaporize install wcode --artifact app --package-path <package> --pkl-path <package>/project.pkl --product <app-product> --configuration release --destination <local-app-data>/Programs/<app-product> --wcode-runtime-artifact <exact-bundle-or-dll-name> --analyze --receipt-path <install-receipt.json>
```

The commands above are a sequence, not a blind batch. Do not run the install
step until build and run evidence for the same package, product, configuration,
and backend are recorded.

## What This Does Not Claim

This process does not claim universal Windows application support, a generic
installer, automatic transitive runtime-closure discovery, fleet parity, or a
completed WCode testing lane. It creates a measured path to those outcomes. The
next platform target must extend the evidence, not erase the boundary that made
the preceding target understandable.
