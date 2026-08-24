@Metadata {
  @PageKind(article)
  @PageColor(blue)
  @TitleHeading("Product Proving Grounds")
  @Available(platform: macOS, introduced: "0.0.1")
}

# Product Proving Grounds

Every vaporware product should carry a proving-ground passport before release
review trusts it. A passport is a typed profile that names the product class,
owning bead, CUJs, required tracks, scenarios, targetable test bundle, receipt
refs, release-doctor checks, and explicit boundaries.

In Vaporize this is a reference implementation of the broader proving-ground
harness and release-review doctrine. Pkl project generation does not own the
doctrine; `tests/proving-grounds/pkl-project-generation` is the concrete
proving ground that drives the standard generator tracks.

The Pkl migration proving grounds have two layers:

- `tests/proving-grounds/xcodegen-to-pkl-parity` holds multiple checked-in
  XcodeGen `project.yml` plus XcodeProjectDefinition `project.pkl` pairs. CUJ-10
  compares the stored pairs, and CUJ-13 regenerates Pkl from every YAML fixture
  to prove the importer creates the same project signature.
- `tests/proving-grounds/pkl-project-generation` holds Pkl-forward generation
  specimens. The root specimen proves the standard generator track shape; the
  `beyond-*` specimens prove Pkl-backed `.xcodeproj` generation behavior that
  goes beyond parity, including resourceful Sparkle app metadata and release
  tool world-state.

The automotive metaphor is useful because it keeps proof concrete. A product
does not merely have tests. It has driven specific tracks.

## Tracks

| Track | Meaning |
| --- | --- |
| `skid-pad` | Bad inputs, malformed state, invalid transitions, and edge-case handling. |
| `hill-climb` | Hard dependencies, resources, permissions, path resolution, and other load-bearing behavior. |
| `endurance-loop` | Repeated install, run, reinstall, replay, or migration cycles. |
| `cold-start-chamber` | Fresh machine, empty cache, hidden build output, or no prior artifact state. |
| `crash-barrier` | Known regressions and expected-fail gates that must stay fixed. |
| `weather-track` | Offline, missing environment, missing credentials, or hostile runtime conditions. |
| `inspection-bay` | Release-doctor, manifests, receipts, metadata, and release packet coherence. |
| `prototype-track` | Simulations and generated fixtures before a product has complete real-world shape. |

## Product Class Defaults

CLI products should prove cold start, resource/path hill climbs, endurance
loops, crash barriers, inspection bay, and prototype track coverage.

Apps should add weather-track coverage for permissions, environment, and
launch/install conditions.

Libraries should carry consumer fixtures, API smoke tests, crash barriers,
inspection bay, and prototype coverage.

Workflows should emphasize skid-pad invalid-state rejection, crash barriers,
inspection bay, and prototype simulations.

Generators should prove skid-pad input rejection, hill-climb graph generation,
crash barriers for unsupported output shapes, inspection-bay release evidence,
and prototype fixtures for generated world-state.

Assistants should prove weather-track behavior for unavailable tools or missing
resources, crash barriers, inspection bay, and prototype transcript fixtures.

Sites should prove cold starts, hostile route/assets weather, crash barriers,
inspection bay, and prototype route fixtures.

## Release Rule

A vaporware product is not release-ready merely because a test bundle passes.
Release review should ask whether the product's proving-ground passport covers
the tracks expected for its class and whether each scenario has a targetable
test bundle plus receipt ref.

The first implementation slice is CUJ-23:

- `VaporizeProductProvingGroundProfile` defines the passport shape.
- `VaporizeProductProvingGroundAdoptionGate` audits required tracks, missing
  CUJs, missing receipts, missing targetable tests, and unknown tracks.
- `VaporizeCUJ23ProductProvingGroundTests` proves a Vaporize CLI passport, the
  Pkl project-generation proving-ground passport, incomplete-passport failure,
  and reusable product-class track defaults.
- Pkl-backed `.xcodeproj` generation is the first checked-in generator proving
  ground driven through the passport harness: it ties
  `tests/proving-grounds/pkl-project-generation`, CUJ-14 graph/scheme tests,
  and release receipts into the CUJ-23 proving-ground audit.
- XcodeGen-to-Pkl parity is now checked through multiple fixtures in
  `tests/proving-grounds/xcodegen-to-pkl-parity`; above-parity project
  generation is checked through Pkl-only `beyond-*` fixtures under
  `tests/proving-grounds/pkl-project-generation`.

## Boundary

Product proving grounds do not approve a release. They make release review
more honest by saying which tracks were driven, which receipts exist, and which
tracks are still missing.
