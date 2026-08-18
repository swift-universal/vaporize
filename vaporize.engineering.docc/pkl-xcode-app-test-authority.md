@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Pkl Xcode App Test Authority")
  @Available(macOS, introduced: "0.0.1")
}

# Pkl Xcode App Test Authority

A native Apple application is an Xcode project authored from `project.pkl`.
It is not a SwiftPM application merely because its Xcode target imports local
Swift packages.

## Canonical invocation

For an app whose Pkl record generates a checked-in project, the test command is:

```sh
vaporize.cli@wrkstrm-core.clia.sh test xcode \
  --artifact app \
  --pkl-path apps/example/project.pkl \
  --xcode-project apps/example/example.xcodeproj \
  --scheme example \
  --configuration debug \
  --xcode-destination 'platform=macOS,arch=arm64' \
  --xcode-build-setting CODE_SIGNING_ALLOWED=NO
```

`--pkl-path` identifies the project-source authority. `--xcode-project` or
`--xcode-workspace` and `--scheme` identify the generated world-state and its
test action. Vaporize dispatches `xcodebuild … test` only after those inputs
are typed and validated.

## What the command does not do

The command does not require a `Package.swift`, materialize SwiftPM editable
dependencies, install an app, or convert test success into release evidence.
Pkl owns configuration, Xcode owns the project and scheme, and Swift packages
remain target dependencies when the Pkl record declares them.

## Evidence boundary

A passing command proves the selected source project and Xcode test action at
that time. It does not prove an installed app, a release, a terminal-evidence
record, or human approval. Source-to-installed parity is a separate gate
documented in Vaporize's support catalog.

The v0.0.2 manifest test scheme for this capability is carried with this DocC
bundle at
`resources/v0.0.2.pkl-xcode-app-test-authority.manifest-test-scheme.su.json`.
