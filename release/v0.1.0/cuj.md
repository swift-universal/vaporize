# Vaporize v0.1.0 - Critical User Journeys

**Status:** release-prep draft  
**Updated:** 2026-06-12T20:26:28Z  
**Component:** `vaporize@wrkstrm-core.cli`

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

- If XcodeGen/project generation is required, the release packet points to
  `FR-VAPORIZE-XCODEGEN-INTEGRATION-substrate-canonical-xcodegen-aware-build`
  rather than smuggling an ad-hoc pre-step.

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

## CUJ-05 - Assistant Inventories Vaporware State

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

## CUJ-06 - Release Reviewer Reads The Packet

1. Reviewer opens `release/v0.1.0/prd.md`.
2. Reviewer opens this CUJ file and checks that each critical journey has
   success and failure truth.
3. Reviewer opens `release/v0.1.0/release-gates.md`.
4. Reviewer opens `release/v0.1.0/evidence/launch-review-packet.json`.
5. Reviewer decides whether v0.1.0 is approved, blocked, or conditionally ready.

Success:

- Release review is based on current artifacts, tests, and known blockers, not
  chat memory.

## Deferred CUJ - Assistant Discovers Targets Through Vaporize

This journey is important but not v0.1.0-green yet.

1. Assistant receives a directory and desired artifact.
2. Assistant runs `vaporize list-targets --package-path <dir>`.
3. Vaporize emits a typed target discovery receipt.
4. Assistant builds or installs from that receipt.

Current status:

- Deferred to
  `FR-VAPORIZE-LIST-TARGETS-substrate-canonical-target-discovery`.

