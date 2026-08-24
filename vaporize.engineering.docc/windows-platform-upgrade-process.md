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

For a SwiftPM-shaped application, WCode can directly delegate build and run to
the selected Swift toolchain. Installation is necessarily app-specific on
Windows, so `install wcode --artifact app` requires the project's declared
PowerShell lifecycle script. Vaporize does not pretend that a generic SwiftPM
CLI install is an app deployment.

## Lifecycle Contract

The public Windows app surface is:

```text
vaporize build wcode --artifact app [options]
vaporize run wcode --artifact app [options] [-- product-arguments]
vaporize install wcode --artifact app --wcode-build-script <script.ps1> [options]
```

The optional `--wcode-build-script` name is retained for compatibility, but it
is a lifecycle script. Vaporize sets these values before invoking it:

| Environment value | Meaning |
| --- | --- |
| `WCODE_OPERATION` | `build`, `run`, or `install`. |
| `WCODE_PACKAGE_PATH`, `WCODE_PRODUCT`, `WCODE_CONFIGURATION`, `WCODE_ARTIFACT` | The selected app identity. |
| `WCODE_DESTINATION`, `WCODE_FORCE_REINSTALL`, `WCODE_SKIP_BUILD`, `WCODE_SKIP_INSTALL`, `WCODE_LAUNCH` | The requested lifecycle controls. Boolean values are `1` or `0`. |
| `WCODE_ARGUMENTS_JSON` | JSON array of product arguments passed after `--`. |

A lifecycle script must switch deliberately on `WCODE_OPERATION`, fail on an
unknown value, and treat the install destination and force flags as deployment
inputs. It must not infer an operation from its filename or silently turn an
install request into a build.

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
3. **Build one pilot app with WCode.** Begin with the smallest Windows app and
   record the package path, product, configuration, backend environment, and
   resulting executable/package location. A direct WCode SwiftPM build is
   sufficient only when the app has no additional lifecycle work.
4. **Run the same pilot through WCode.** Pass product arguments after `--` and
   preserve the receipt. A successful build is not a run proof; validate that
   the expected backend and runtime dependencies are actually selected.
5. **Install through the lifecycle script.** Use a dedicated install invocation
   and have the script perform the project's package/deployment operation. The
   script must honor `WCODE_OPERATION=install`; validate the installed artifact
   at the selected destination and, when requested, launch it.
6. **Expand only after the pilot is repeatable.** Add another app or Windows
   platform target one at a time. Re-run the preceding successful gates before
   changing the toolchain, backend, packaging format, or deployment location.

The first app is a proving ground, not fleet parity. A green result for one
backend, SDK, or package shape does not certify the others.

## Evidence and Stop Conditions

Use `--receipt-path` and `--analyze` for lifecycle commands when receipts are
available in the workstream. Keep the script, command line, toolchain version,
backend environment, installed location, and focused-test result together in
the app's upgrade record.

Stop and open or update the owning bead when any of these occurs:

- a raw Swift command is asked to install, run, or package an app;
- a WCode lifecycle script cannot identify `WCODE_OPERATION` or produces an
  ambiguous output location;
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

```powershell
# 0. Establish the source/toolchain baseline.
swift --version
swift package dump-package
swift test --filter VaporizeCUJ01SwiftPMCLITests

# 1. Build and run the chosen Windows app through its app authority.
vaporize build wcode --artifact app --package-path <package> --product <app-product> --configuration debug --wcode-environment SCUI_DEFAULT_BACKEND=WinUIBackend --analyze --receipt-path <build-receipt.json>
vaporize run wcode --artifact app --package-path <package> --product <app-product> --configuration debug --analyze --receipt-path <run-receipt.json> -- <app-arguments>

# 2. Let the project own deployment details, but preserve Vaporize's lifecycle boundary.
vaporize install wcode --artifact app --package-path <package> --product <app-product> --configuration release --destination <destination> --wcode-build-script scripts/wcode-lifecycle.ps1 --analyze --receipt-path <install-receipt.json>
```

The commands above are a sequence, not a blind batch. Do not run the install
step until build and run evidence for the same package, product, configuration,
and backend are recorded.

## What This Does Not Claim

This process does not claim universal Windows application support, a generic
installer, fleet parity, or a completed WCode testing lane. It creates a
measured path to those outcomes. The next platform target must extend the
evidence, not erase the boundary that made the preceding target understandable.
