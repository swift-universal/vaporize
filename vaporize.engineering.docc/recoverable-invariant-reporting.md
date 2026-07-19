# Recoverable Invariant Reporting

Vaporize uses Point-Free's `swift-issue-reporting` 2.0.0 to make recoverable
internal invariant failures visible without turning the reporter itself into a
fatality policy.

## Severity And Containment Ladder

Choose the failure mechanism before adding a report site:

1. Expected domain or user failure: return a typed error, `Result`, validation
   result, or user-facing state.
2. Recoverable internal invariant: call `reportIssue`, then explicitly return,
   quarantine, discard, or use a known-safe fallback.
3. Unsafe continuation: stop with `preconditionFailure` or `fatalError`.
4. External operational failure: use structured logging, telemetry, retry, or
   user-facing recovery.

Every recoverable-invariant adoption must name four things in review: the
invariant that failed, the containment that makes continuation safe, the
reporters that observe it, and the test or receipt that proves visibility.

## What Appears In Vaporize

Build, test, and run are different evidence boundaries:

- `vaporize build` compiles the reporter but does not execute application
  runtime issue sites. A successful build therefore reports runtime issue
  execution as not run, not as zero issues.
- `vaporize test` lets the library's default reporter preserve native test
  failures while Vaporize supplies a request-scoped JSONL sink. With
  `--receipt-path`, the receipt embeds redacted events, expected and unexpected
  counts, sink integrity, process outcome, and test-assertion detection before
  Vaporize returns the child process exit. A green uninstrumented test records
  the runtime issue phase as run, the sink as absent, and both counts as zero.
- `vaporize run` can expose the structured stream only after the launched
  process is given the request-scoped environment and Vaporize ingests the
  resulting file. That launch path remains tracked by
  `task-vaporize-run-runtime-issue-ingestion-2026-07-17`.

The reporter does not replace `IssueReporter.default`. Installation appends it
so Xcode runtime warnings and Swift Testing failures retain their upstream
behavior.

Swift Testing's native known-issue context does not propagate expectation state
to appended custom reporters. Expected issue scopes therefore pair the native
known-issue API with `VaporizeIssueReporting.withExpectedReporter`; the default
reporter preserves native test behavior while the structured event records
`expected: true` and informational severity.

## Structured Event Contract

`VaporizeIssueEvent` schema version `0.1.0` records an event identifier and
timestamp, severity, message, source location, `test` or `run` phase, Vaporize
request identifier, product, process identifier, expected-state marker, and a
redaction summary. The sink appends one JSON object per line under an
in-process lock.

The `vaporize-test-execution` receipt keeps process, assertion, and issue
evidence separate. A malformed sink is recorded as malformed and cannot be
reported as a clean zero. Repeated records with the same event identifier are
counted once. Raw child stdout and stderr are forwarded to their original file
descriptors before receipt emission.

Consumers opt in with these environment values:

- `VAPORIZE_ISSUE_REPORT_PATH`: request-scoped JSONL sink path.
- `VAPORIZE_REQUEST_ID`: identifier shared with the Vaporize receipt.
- `VAPORIZE_EXECUTION_PHASE`: either `test` or `run`.

Vaporize supplies those values but does not inject code into an arbitrary test
or application process. An adopting process installs the appended reporter once
at its entry point:

```swift
VaporizeIssueReporting.installFromEnvironment(product: "my-product")
```

Tests that need a narrow scope can avoid global installation:

```swift
if let configuration = VaporizeIssueReporting.configurationFromEnvironment(
  product: "my-product"
) {
  VaporizeIssueReporting.withReporter(configuration: configuration) {
    exerciseRecoverableInvariant()
  }
}
```

Inside a native known-issue scope, use `withExpectedReporter` in the same
position so the structured event carries `expected: true`. An absent sink is
therefore explicit receipt state: it is not silently rewritten to `valid`, even
when the child process passes and the semantic counts are zero.

Messages replace the current home-directory path with `<home>` and are bounded
to 4,096 characters by default. Source paths are reduced to
`<redacted>/<filename>` unless an adopter explicitly enables absolute paths;
even then, the home directory is redacted. Sink failures write directly to
standard error and never recursively report an issue or crash the consumer.

## Dependency And Rollback Boundary

The package graph pins `swift-issue-reporting` exactly at 2.0.0 and imports only
its `IssueReporting` product. This adoption does not add `swift-case-paths` or
legacy compatibility-overlay dependencies.

Rollback is narrow: remove the `swift-issue-reporting` package dependency, the
`VaporizeIssueReporting` product and target, its focused test target, and any
consumer installation calls. Existing typed errors, fatal checks, logging, and
Point-Free's default reporter behavior outside this target remain unchanged.
