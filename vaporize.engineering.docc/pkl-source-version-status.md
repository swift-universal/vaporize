# Pkl Source Version Status

@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Pkl Source Version Status")
  @PageImage(purpose: icon, source: "pkl-source-version-status-icon", alt: "A versioned Pkl carrier flowing through a stable source entrypoint")
  @PageImage(purpose: card, source: "pkl-source-version-status-card", alt: "A Pkl entrypoint, a versioned source carrier, and a source-only version receipt")
  @Available(macOS, introduced: "0.0.1")
}

@Image(source: "pkl-source-version-status-hero", alt: "A payload-free Pkl entrypoint composes a versioned source carrier into a source-only version status receipt")

`vaporize version-status` is a source observation for native Apple apps. It
reports a declared marketing version and build number only when it can resolve
them from an owner-controlled carrier. It does not read a generated project as
an authority and it does not turn a source declaration into installed-runtime
or release evidence.

## App-Home Grammar

The scanner recognizes one direct app home at either of these forms:

```text
private/apple/apps/<app>
product-lines/<product-line>/apps/<app>
```

The second form lets a Kura product line own its app where the product lives;
it is not a fallback path or a reconstruction from a project name. A carrier is
eligible only when it is directly in that app home and the owned-surface
inventory classifies it as active-owned.

## Pkl Authority

For a Pkl app, the scanner evaluates the active `project.pkl` composition
entrypoint through `XcodeProjectPklLoader`. A payload such as
`project-v000_000_001.pkl` remains the versioned source declaration that the
entrypoint composes. The report records the entrypoint as the reproducible
evaluation carrier; it does not infer a payload filename, edit Pkl, or fall
back to a generated `.xcodeproj`.

When a legacy `project.yml` shares the direct app home, the transitional YAML
carrier remains the selected source authority until its migration is complete.
An unreadable Pkl entrypoint is a loud `unreadable-project-pkl` finding, not a
compliant row.

## Use

```sh
vaporize.cli@wrkstrm-core.clia.sh version-status \
  --path private/universal/kura-spaces/product-lines \
  --format json
```

Rows identify the target, source carrier, and each resolved configuration.
`0.0.x` is the source-version policy used by this report. It is a policy check
over declared source values, not an assertion about the package's public
release version, a persisted wire version, or an App Store version.

## Evidence Boundary

The report proves that the named Pkl entrypoint evaluated to a source project
model at observation time. It does not prove generated-project parity, an
Xcode test pass, an installed app bundle, publication, Launch Review, or human
approval. Those claims require their own receipts and authority holders.

The v0.0.4 manifest test scheme is bundled at
`resources/v0.0.4.pkl-product-line-version-status.manifest-test-scheme.su.json`.
