# Toolchain Triage

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Toolchain Triage")
  @PageImage(purpose: icon, source: "toolchain-triage-icon", alt: "Two independent toolchain lanes converge on a diagnosis point.")
  @PageImage(purpose: card, source: "toolchain-triage-card", alt: "Parallel Xcode and Swiftly provider lanes that remain distinct until diagnosis.")
}

@Image(source: "toolchain-triage-hero", alt: "Independent Xcode and Swiftly selection lanes each lead to a shared evidence diagnosis without crossing state boundaries.")

Use this page when a Swift or Xcode operation fails before a project begins to
compile. The goal is to identify whether the failure belongs to Xcode, the
Vaporize executable, the Swiftly proxy, or the selected toolchain.

## Inspect Xcode Without Changing it

```sh
xcode-select -p
xcodebuild -version
xcrun swift --version
```

These commands observe the active Xcode developer directory and the Swift
compiler that Xcode resolves. A successful `xcrun swift --version` proves only
that Xcode's Swift is available. It does not prove that Vaporize or the shell
`swift` proxy has the same capability.

Use Vaporize's Xcode provider to inspect the same selection surface through the
product boundary:

```sh
vaporize.cli@wrkstrm-core.clia.sh toolchain-selection xcode -- select --print-path
```

`--print-path` is observational. A `--switch` or `--reset` request mutates the
machine-wide Xcode selection and must be an explicit later action.

## Inspect Vaporize's Compiled Capability

```sh
vaporize.cli@wrkstrm-core.clia.sh --version
vaporize.cli@wrkstrm-core.clia.sh toolchain-selection --help
```

The toolchain help must say that the build includes the embedded Swiftly
provider before the Swift selection command can work. If it says the provider
was omitted, this is an installed-artifact capability defect. Do not describe
it as an Xcode failure.

## Inspect the Swift Proxy

```sh
command -v swift
ls -l "$(command -v swift)"
readlink "$(command -v swift)"
```

The shell `swift` can be a Swiftly proxy link to Vaporize. When it is, a
provider-less installed Vaporize artifact causes `swift --version` to fail even
though `xcrun swift --version` succeeds. That is a source-installed parity
problem; continue with <doc:source-installed-parity>.

## Query, Do Not Select, Swiftly State

With a provider-bearing Vaporize artifact, the following asks Swiftly to report
its active state without requesting a new selector:

```sh
vaporize.cli@wrkstrm-core.clia.sh toolchain-selection swift -- use --format json
```

Only append a selector after choosing its scope. For example,
`--global-default` changes the default compiler used where no project-level
selection exists. Record the output receipt before and after that change.

## Decision Table

| Observation | Meaning | Next page |
| --- | --- | --- |
| `xcrun swift --version` fails | Xcode/Command Line Tools lane is unavailable. | Escalate with <doc:support-packet>. |
| Xcode Swift works; Vaporize says provider omitted | Installed Vaporize capability is incomplete. | <doc:source-installed-parity> |
| Provider is present; no Swiftly proxy link is active | Selection has not been made or is scoped elsewhere. | Choose scope, then use the Swift provider. |
| Build is taking time with active compiler CPU | The build is active, not necessarily stalled. | <doc:bounded-build-observation> |
