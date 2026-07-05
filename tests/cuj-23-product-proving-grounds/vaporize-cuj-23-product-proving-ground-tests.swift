import Foundation
import Testing
import VaporizeTestSupport

@Test("cuj-23 product proving-ground profile gives vaporize a passport")
func productProvingGroundProfileGivesVaporizeAPassport() throws {
  let profile = vaporizeCLIProvingGroundProfile()
  let audit = VaporizeProductProvingGroundAdoptionGate.audit(
    profile: profile,
    requiredCUJRefs: ["CUJ-22", "CUJ-23"]
  )

  #expect(profile.documentKind == "vaporware-product-proving-ground-profile")
  #expect(profile.productSlug == "vaporize.cli@wrkstrm-core.clia.sh")
  #expect(profile.productClass == "cli")
  #expect(profile.owningBeadRef == "beads/FR-VAPORIZE-PRODUCT-PROVING-GROUNDS-2026-07-05.beads-issue.json")
  #expect(profile.requiredTrackSlugs == VaporizeProductProvingGroundAdoptionGate.requiredTracks(for: "cli"))
  #expect(profile.scenarios.map(\.trackSlug) == [
    "cold-start-chamber",
    "hill-climb",
    "endurance-loop",
    "crash-barrier",
    "inspection-bay",
    "prototype-track",
  ])
  #expect(audit.coverageStatus == "pass")
  #expect(audit.missingTrackSlugs.isEmpty)
  #expect(audit.missingCUJRefs.isEmpty)
  #expect(audit.missingReceiptScenarioSlugs.isEmpty)
  #expect(audit.missingTargetableTestScenarioSlugs.isEmpty)
}

@Test("cuj-23 product proving-ground gate fails incomplete passports")
func productProvingGroundGateFailsIncompletePassports() throws {
  var profile = vaporizeCLIProvingGroundProfile()
  profile.scenarios.removeAll { $0.trackSlug == "inspection-bay" }
  profile.scenarios[0].receiptRef = ""
  profile.scenarios[1].targetableTestBundle = ""

  let audit = VaporizeProductProvingGroundAdoptionGate.audit(
    profile: profile,
    requiredCUJRefs: ["CUJ-22", "CUJ-23"]
  )

  #expect(audit.coverageStatus == "fail")
  #expect(audit.missingTrackSlugs == ["inspection-bay"])
  #expect(audit.missingReceiptScenarioSlugs == ["swiftpm-cli-cold-start-install"])
  #expect(audit.missingTargetableTestScenarioSlugs == ["swiftpm-resource-hill-climb"])
}

@Test("cuj-23 proving-ground profile covers the Pkl project-generation proving ground")
func productProvingGroundProfileCoversPklProjectGeneration() throws {
  let profile = vaporizePklXcodeProjectGenerationProvingGroundProfile()
  let audit = VaporizeProductProvingGroundAdoptionGate.audit(
    profile: profile,
    requiredCUJRefs: ["CUJ-14", "CUJ-23"]
  )

  #expect(profile.documentKind == "vaporware-product-proving-ground-profile")
  #expect(profile.productSlug == "vaporize-pkl-xcodeproj-generation@wrkstrm-core.feature")
  #expect(profile.productClass == "generator")
  #expect(profile.requiredTrackSlugs == VaporizeProductProvingGroundAdoptionGate.requiredTracks(for: "generator"))
  #expect(profile.scenarios.map(\.slug) == [
    "pkl-project-input-skid-pad",
    "pkl-project-graph-hill-climb",
    "pkl-unsupported-target-crash-barrier",
    "pkl-project-release-inspection-bay",
    "pkl-project-prototype-track",
  ])
  #expect(profile.scenarios.allSatisfy { $0.targetableTestBundle == "VaporizeCUJ14PklXcodeProjectGenerationTests" })
  #expect(audit.coverageStatus == "pass")
  #expect(audit.missingTrackSlugs.isEmpty)
  #expect(audit.missingCUJRefs.isEmpty)
  #expect(audit.missingReceiptScenarioSlugs.isEmpty)
  #expect(audit.missingTargetableTestScenarioSlugs.isEmpty)
}

@Test("cuj-23 product-class catalog defines reusable proving-ground tracks")
func productClassCatalogDefinesReusableTracks() throws {
  let productClasses = ["cli", "app", "library", "workflow", "generator", "assistant", "site"]

  for productClass in productClasses {
    let tracks = VaporizeProductProvingGroundAdoptionGate.requiredTracks(for: productClass)

    #expect(tracks.contains("inspection-bay"))
    #expect(tracks.contains("crash-barrier"))
    #expect(tracks.contains("prototype-track"))
    #expect(tracks.allSatisfy { track in
      track == track.lowercased() && !track.contains(" ")
    })
  }
}

private func vaporizeCLIProvingGroundProfile() -> VaporizeProductProvingGroundProfile {
  VaporizeProductProvingGroundProfile(
    productSlug: "vaporize.cli@wrkstrm-core.clia.sh",
    productClass: "cli",
    owningBeadRef: "beads/FR-VAPORIZE-PRODUCT-PROVING-GROUNDS-2026-07-05.beads-issue.json",
    cujRefs: ["CUJ-22", "CUJ-23"],
    requiredTrackSlugs: VaporizeProductProvingGroundAdoptionGate.requiredTracks(for: "cli"),
    scenarios: [
      scenario(
        slug: "swiftpm-cli-cold-start-install",
        title: "swiftpm cli cold start install",
        trackSlug: "cold-start-chamber",
        proofKind: "install-run-proof",
        receiptRef: "command-receipt://vaporize/cuj22/resource-cli/checked-in-resource-vault"
      ),
      scenario(
        slug: "swiftpm-resource-hill-climb",
        title: "swiftpm resource hill climb",
        trackSlug: "hill-climb",
        proofKind: "resource-loading-proof",
        receiptRef: "command-receipt://vaporize/cuj22/resource-cli/processed-json"
      ),
      scenario(
        slug: "resource-reinstall-endurance-loop",
        title: "resource reinstall endurance loop",
        trackSlug: "endurance-loop",
        proofKind: "repeat-install-proof",
        receiptRef: "command-receipt://vaporize/cuj22/resource-cli/stale-reinstall"
      ),
      scenario(
        slug: "legacy-product-crash-barrier",
        title: "legacy product crash barrier",
        trackSlug: "crash-barrier",
        proofKind: "negative-gate-proof",
        receiptRef: "command-receipt://vaporize/cuj22/resource-cli/legacy-product-gate"
      ),
      scenario(
        slug: "release-doctor-inspection-bay",
        title: "release doctor inspection bay",
        trackSlug: "inspection-bay",
        proofKind: "release-spine-proof",
        receiptRef: "release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json"
      ),
      scenario(
        slug: "simulation-prototype-track",
        title: "simulation prototype track",
        trackSlug: "prototype-track",
        proofKind: "simulation-proof",
        receiptRef: "tests/vaporize-test-support/SimulationProvingGroundTestSupport.swift"
      ),
    ],
    releaseDoctorCheckRefs: [
      "product-proving-ground-doc",
      "coverage-product-proving-ground-test-bundle",
      "launch-review-product-proving-ground-evidence-ref",
    ],
    metadata: [
      "cuj": "23",
      "metaphor": "automotive-proving-grounds",
    ]
  )
}

private func vaporizePklXcodeProjectGenerationProvingGroundProfile() -> VaporizeProductProvingGroundProfile {
  VaporizeProductProvingGroundProfile(
    productSlug: "vaporize-pkl-xcodeproj-generation@wrkstrm-core.feature",
    productClass: "generator",
    owningBeadRef: "beads/FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl.beads-issue.json",
    cujRefs: ["CUJ-14", "CUJ-23"],
    requiredTrackSlugs: VaporizeProductProvingGroundAdoptionGate.requiredTracks(for: "generator"),
    scenarios: [
      scenario(
        slug: "pkl-project-input-skid-pad",
        title: "pkl project input skid pad",
        trackSlug: "skid-pad",
        proofKind: "input-rejection-proof",
        receiptRef: "tests/proving-grounds/pkl-project-generation/proving-ground-passport.json",
        targetableTestBundle: "VaporizeCUJ14PklXcodeProjectGenerationTests"
      ),
      scenario(
        slug: "pkl-project-graph-hill-climb",
        title: "pkl project graph hill climb",
        trackSlug: "hill-climb",
        proofKind: "project-graph-generation-proof",
        receiptRef: "tests/proving-grounds/pkl-project-generation/project.pkl",
        targetableTestBundle: "VaporizeCUJ14PklXcodeProjectGenerationTests"
      ),
      scenario(
        slug: "pkl-unsupported-target-crash-barrier",
        title: "pkl unsupported target crash barrier",
        trackSlug: "crash-barrier",
        proofKind: "negative-gate-proof",
        receiptRef: "tests/proving-grounds/pkl-project-generation/proving-ground-passport.json",
        targetableTestBundle: "VaporizeCUJ14PklXcodeProjectGenerationTests"
      ),
      scenario(
        slug: "pkl-project-release-inspection-bay",
        title: "pkl project release inspection bay",
        trackSlug: "inspection-bay",
        proofKind: "release-spine-proof",
        receiptRef: "release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json",
        targetableTestBundle: "VaporizeCUJ14PklXcodeProjectGenerationTests"
      ),
      scenario(
        slug: "pkl-project-prototype-track",
        title: "pkl project prototype track",
        trackSlug: "prototype-track",
        proofKind: "generated-fixture-proof",
        receiptRef: "tests/proving-grounds/pkl-project-generation/project.pkl",
        targetableTestBundle: "VaporizeCUJ14PklXcodeProjectGenerationTests"
      ),
    ],
    releaseDoctorCheckRefs: [
      "coverage-pkl-xcodeproj-graph-scheme-test-bundle",
      "coverage-product-proving-ground-test-bundle",
      "product-proving-ground-doc",
    ],
    metadata: [
      "cuj": "14,23",
      "feature": "pkl-xcodeproj-generation",
      "gate": "GATE-14-pkl-project-generation",
      "provingGround": "tests/proving-grounds/pkl-project-generation",
    ]
  )
}

private func scenario(
  slug: String,
  title: String,
  trackSlug: String,
  proofKind: String,
  receiptRef: String,
  targetableTestBundle: String = "VaporizeCUJ23ProductProvingGroundTests"
) -> VaporizeProductProvingGroundScenario {
  VaporizeProductProvingGroundScenario(
    slug: slug,
    title: title,
    trackSlug: trackSlug,
    proofKind: proofKind,
    maturity: "release-gated",
    targetableTestBundle: targetableTestBundle,
    receiptRef: receiptRef
  )
}
