@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Test Service Adoption")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Test Service Adoption

Every Vaporize test target composes `VaporizeTestSupport`. That is a required
Core test-service adapter, not a convenience import. The adapter composes the
portable Core `TestServiceAdoptionPolicy` cartridge with the reusable
`TestFixtureLifecycle` cartridge from Swift Universal.

## Prime Example

`VaporizeCUJ32TestServiceAdoptionTests` is the Core prime example. It proves
two things together:

1. `@Test(.fixtureLifecycle(...))` gives a test a unique temporary session and
   allows it to create mock-only text fixtures.
2. The manifest audit rejects a Vaporize test target that omits the required
   `VaporizeTestSupport` composition.

The first production consumer is the App Store Snapshot package. Its test-only
dependency uses the same `TestFixtureLifecycle` cartridge directly, so the
Core example is a composition pattern rather than a Vaporize-only helper.

## Adoption Rule

A test target must compose the package's Core test-service adapter. A service
is available to every test target, but it only allocates state when a test
requests it. For filesystem fixtures, use the `fixtureLifecycle` Swift Testing
trait; the service creates a managed temporary root before the test and removes
it on success or failure.

Do not replace this with ad-hoc UUID temporary directories, repository-local
fixture output, or a global before/after hook. Different state classes get
different cartridges: filesystem fixtures, process-environment overrides,
clocks, and network doubles must remain separately composable services.

## Legacy Migration

An existing target may have a named migration exception only when it records an
owner, reason, and expiry. An active exception remains visible as a warning in
the adoption report. An expired exception fails the audit. New test targets do
not receive an exception by default.

The policy is intentionally source-auditable. It verifies package composition;
source tests then prove service behavior. Neither result is a release approval
or an installed-runtime proof.
