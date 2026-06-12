# Vaporize v0.0.1 - Critical User Journeys

**Status:** release-prep draft; blocked pending Pkl project-generation migration
**Updated:** 2026-06-12T21:16:27Z
**Component:** `vaporize@wrkstrm-core.cli`
**Tool classification:** `internal-essential-tool`

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

1. Reviewer opens `release/v0.0.1/prd.md`.
2. Reviewer opens this CUJ file and checks that each critical journey has
   success and failure truth.
3. Reviewer opens `release/v0.0.1/release-gates.md`.
4. Reviewer opens `release/v0.0.1/evidence/launch-review-packet.json`.
5. Reviewer verifies that Vaporize is classified as an internal essential tool,
   not a public release artifact.
6. Reviewer decides whether v0.0.1 is approved, blocked, or conditionally ready.

Success:

- Release review is based on current artifacts, tests, and known blockers, not
  chat memory.

## Deferred CUJ - Assistant Builds A Pkl-Backed Apple Project

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
- Existing XcodeGen surfaces remain historical compatibility, not the forward
  release path for our own apps.

## Deferred CUJ - Assistant Discovers Targets Through Vaporize

This journey is important but not v0.0.1-green yet.

1. Assistant receives a directory and desired artifact.
2. Assistant runs `vaporize list-targets --package-path <dir>`.
3. Vaporize emits a typed target discovery receipt.
4. Assistant builds or installs from that receipt.

Current status:

- Deferred to
  `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`.
