# Toolchain Triage

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Toolchain Triage")
  @PageImage(purpose: icon, source: "toolchain-triage-icon", alt: "Two independent toolchain lanes converge on a diagnosis point.")
  @PageImage(purpose: card, source: "toolchain-triage-card", alt: "Xcode selection and Temper-owned Swift lanes remain distinct until diagnosis.")
}

@Image(source: "toolchain-triage-hero", alt: "Independent Xcode and Temper-owned Swift lanes each lead to a shared evidence diagnosis without crossing state boundaries.")

Use this page when a Swift or Xcode operation fails before a project begins to
compile. The goal is to identify whether the failure belongs to Xcode, the
Vaporize executable, Temper, or the selected Swift toolchain.

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
```

Vaporize version and receipt evidence identify the materialization tool. On
macOS, `toolchain-selection --help` describes only the Xcode selection lane.
Swift selection is not a Vaporize artifact capability.

## Inspect Swift Ownership

```sh
command -v swift
ls -l "$(command -v swift)"
readlink "$(command -v swift)"
```

The shell `swift` must not proxy through Vaporize. If its link resolves to a
Vaporize executable, record that stale topology and repair selection through
Temper. Compare `swift --version` with `xcrun swift --version` on macOS without
conflating their ownership boundaries.

## Query Temper State

Temper owns Swift state. Query it without requesting a new selector:

```sh
temper swift use --format json
```

Only append a selector after choosing its scope. For example,
`--global-default` changes the default compiler used where no project-level
selection exists. Record the output receipt before and after that change.

## Decision Table

| Observation | Meaning | Next page |
| --- | --- | --- |
| `xcrun swift --version` fails | Xcode/Command Line Tools lane is unavailable. | Escalate with <doc:support-packet>. |
| Xcode Swift works; `swift` on `PATH` fails | Temper or selected-Swift state is unavailable. | Query Temper state and inspect the `swift` link. |
| `swift` links to Vaporize | A retired proxy topology is still installed. | Record identity, then repair the link through Temper. |
| Build is taking time with active compiler CPU | The build is active, not necessarily stalled. | <doc:bounded-build-observation> |
