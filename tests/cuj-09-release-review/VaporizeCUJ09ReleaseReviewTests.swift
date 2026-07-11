import Foundation
import Testing

@Test("CUJ-09 release review artifacts exist")
func releaseReviewArtifactsExist() {
  for relativePath in [
    "release/v0.0.1/product-definition.md",
    "release/v0.0.1/prd.md",
    "release/v0.0.1/prd-review-session.md",
    "release/v0.0.1/cuj.md",
    "release/v0.0.1/release-gates.md",
    "release/v0.0.1/why-vaporize.md",
    "release/v0.0.1/performance-marketing-claims.md",
    "release/v0.0.1/public-brochure.md",
    "release/v0.0.1/public-brochure.html",
    "release/v0.0.1/user-manual.md",
    "release/v0.0.1/public-changelog.md",
    "release/v0.0.1/evidence/audience-packet.su.json",
    "release/v0.0.1/evidence/launch-review-blocker-disposition.json",
    "vaporize.engineering.docc/index.md",
    "vaporize.engineering.docc/feature-catalog.md",
    "vaporize.engineering.docc/modularity-and-ownership-boundaries.md",
    "vaporize.engineering.docc/vaporware-modification-request-discipline.md",
    "vaporize.engineering.docc/product-and-policy.md",
    "vaporize.engineering.docc/command-and-artifact-architecture.md",
    "vaporize.engineering.docc/project-generation-and-migration.md",
    "vaporize.engineering.docc/release-evidence-and-gates.md",
    "vaporize.engineering.docc/benchmark-and-size-evidence.md",
    "vaporize.engineering.docc/target-feature-inspection.md",
    "vaporize.engineering.docc/feature-test-lifecycle.md",
    "vaporize.engineering.docc/cuj-state-testing-methodology.md",
    "vaporize.engineering.docc/release-doctor.md",
    "vaporize.engineering.docc/swiftpm-cli-resource-bundle-installs.md",
    "vaporize.engineering.docc/product-proving-grounds.md",
    "release/v0.0.1/evidence/launch-review-packet.json",
    "release/v0.0.1/evidence/cuj-state-coverage.json",
    "release/v0.0.1/evidence/hello-world-google-target-features-inspection.receipt.json",
    "release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json",
    "release/v0.0.1/evidence/vaporize-consumer-facing-gate-carrie-cmo-ownership-modification.receipt.json",
    "release/v0.0.1/evidence/creative-selection-v0.2-list-targets.receipt.json",
    "release/v0.0.1/evidence/creative-selection-v0.2-workspace-cache-discovery.receipt.json",
  ] {
    #expect(FileManager.default.fileExists(atPath: packageRoot.appendingPathComponent(relativePath).path))
  }
}

@Test("CUJ-09 launch-review packet is valid JSON and internal essential")
func launchReviewPacketIsValidJSONAndInternalEssential() throws {
  let packet = try readJSONObject(relativePath: "release/v0.0.1/evidence/launch-review-packet.json")

  #expect(packet["subjectAppSlug"] as? String == "vaporize.cli@wrkstrm-core.clia.sh")
  #expect(packet["subjectWareKindSlug"] as? String == "internal-essential-cli")
  let releaseTarget = try #require(packet["releaseTarget"] as? [String: Any])
  #expect(releaseTarget["toolClassification"] as? String == "internal-essential-tool")
  let evidenceRefs = try #require(packet["evidenceRefs"] as? [[String: Any]])
  let gateResults = try #require(packet["gateResults"] as? [[String: Any]])
  let consumerFacingGateOwnership = try #require(packet["consumerFacingGateOwnership"] as? [String: Any])
  let signoffs = try #require(packet["signoffs"] as? [String: Any])
  let humanReviewPolicy = try #require(packet["humanReviewPolicy"] as? [String: Any])
  let gateStatuses = gateResults.compactMap { $0["status"] as? String }
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 public brochure marketing site" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 public brochure audience packet" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 user manual" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 public brochure" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Carrie CMO consumer-facing public-disclosure gate owner" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "CMO consumer-facing public-disclosure gate ownership bead" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize consumer-facing gate Carrie CMO ownership correction receipt" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize CUJ-22 resource CLI install test bundle" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize CUJ-23 product proving-ground adoption test bundle" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "SwiftPM CLI resource-bundle install engineering doc" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Product proving-ground passports engineering doc" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize SwiftPM CLI resource-bundle install modification receipt" })
  #expect(evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 launch-review blocker disposition" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-24-positioning-and-benchmark-explainer" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-25-performance-marketing-claims" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-26-product-definition-user-journeys-choice-argument" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-27-runtime-sample-series-apple-artifact-ingestion" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-29-wrkstrm-app-minimums-inspection" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-30-engineering-docc-catalog" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-31-pre-code-prd-review-session" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-32-vaporware-modification-request-discipline" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-33-release-doctor" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-34-project-target-discovery" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-35-workspace-product-cache-discovery" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-36-xcode-workspace-scheme-listing" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-37-cuj-state-coverage" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-38-public-disclosure-surfaces" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-39-resource-cli-install" })
  #expect(gateResults.contains { $0["gateRef"] as? String == "GATE-40-product-proving-grounds" })
  #expect(packet["packetStatus"] as? String == "evidence-ready-pending-human-review-blocked-for-internal-release")
  #expect(humanReviewPolicy["approvalStatusRequiresHumanReview"] as? Bool == true)
  #expect(humanReviewPolicy["automationSignerAllowed"] as? Bool == false)
  #expect(humanReviewPolicy["machineProofMayApproveGate"] as? Bool == false)
  #expect(!gateStatuses.contains("PASS"))
  #expect(!gateStatuses.contains("PASS-WITH-NOTE"))
  #expect(gateStatuses.filter { $0 == "EVIDENCE-READY-PENDING-HUMAN-REVIEW" }.count == 34)
  #expect(gateStatuses.filter { $0.hasPrefix("BLOCKED") }.count == 1)
  #expect(
    gateResults
      .filter { $0["status"] as? String == "EVIDENCE-READY-PENDING-HUMAN-REVIEW" }
      .allSatisfy {
        $0["humanReviewRequired"] as? Bool == true
          && $0["humanReviewRef"] as? NSNull != nil
          && $0["evidenceStatus"] as? String != nil
      }
  )
  #expect(consumerFacingGateOwnership["ownerStatus"] as? String == "assigned-not-signed-off")
  #expect(consumerFacingGateOwnership["ownerName"] as? String == "Carrie CMO")
  #expect(
    consumerFacingGateOwnership["ownerOccupationSlug"] as? String
      == "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org"
  )
  #expect(signoffs["audienceApproverSignoffRef"] as? NSNull != nil)
  #expect(signoffs["founderSignoffRef"] as? NSNull != nil)
}

@Test("CUJ-09 CUJ coverage contract is valid JSON and names the floor")
func cujCoverageContractIsValidJSONAndNamesTheFloor() throws {
  let coverage = try readJSONObject(relativePath: "release/v0.0.1/evidence/cuj-test-coverage.json")
  let counts = try #require(coverage["counts"] as? [String: Any])

  #expect(counts["activeCUJCount"] as? Int == 27)
  #expect(counts["deferredCUJCount"] as? Int == 1)
  #expect(counts["requiredSwiftTestObligationCount"] as? Int == 132)
  #expect(counts["requiredReleaseEvidenceCheckCount"] as? Int == 14)
  #expect(counts["requiredTargetableTestObligationCount"] as? Int == 146)
  #expect(counts["currentExecutableSwiftTestCount"] as? Int == 196)
  let breakdown = try #require(counts["currentExecutableSwiftTestBreakdown"] as? [String: Any])
  #expect(breakdown["VaporizeCUJ01SwiftPMCLITests"] as? Int == 21)
  #expect(breakdown["VaporizeCUJ02MacAppTests"] as? Int == 29)
  #expect(breakdown["VaporizeCUJ06JSONValidationTests"] as? Int == 9)
  #expect(breakdown["VaporizeCUJ07VaporInventoryTests"] as? Int == 18)
  #expect(breakdown["VaporizeCUJ10YMLPklComparisonTests"] as? Int == 5)
  #expect(breakdown["VaporizeCUJ13YMLPklImportTests"] as? Int == 9)
  #expect(breakdown["VaporizeCUJ14PklXcodeProjectGenerationTests"] as? Int == 7)
  #expect(breakdown["VaporizeCUJ17ReleaseDoctorTests"] as? Int == 7)
  #expect(breakdown["VaporizeCUJ21CUJStateTests"] as? Int == 6)
  #expect(breakdown["VaporizeCUJ22ResourceCLIInstallTests"] as? Int == 8)
  #expect(breakdown["VaporizeCUJ23ProductProvingGroundTests"] as? Int == 4)
  #expect(breakdown["VaporizeCUJ25PortfolioAuditTests"] as? Int == 6)
  #expect(breakdown["VaporizeCUJ26AutomatedProofLedgerTests"] as? Int == 5)
  #expect(breakdown["VaporizeCUJ27ProjectCoverageLedgerTests"] as? Int == 4)
}

@Test("CUJ-09 CUJ-state coverage contract is valid JSON and complete")
func cujStateCoverageContractIsValidJSONAndComplete() throws {
  let coverage = try readJSONObject(relativePath: "release/v0.0.1/evidence/cuj-state-coverage.json")
  let requiredStateIDs = try #require(coverage["requiredStateIDs"] as? [String])
  let coveredStateIDs = try #require(coverage["coveredStateIDs"] as? [String])
  let uncoveredStateIDs = try #require(coverage["uncoveredStateIDs"] as? [String])
  let unknownStateIDs = try #require(coverage["unknownStateIDs"] as? [String])
  let duplicateProofStateIDs = try #require(coverage["duplicateProofStateIDs"] as? [String])
  let proofs = try #require(coverage["proofs"] as? [[String: Any]])
  let proofStateIDs = Set(proofs.compactMap { $0["stateID"] as? String })

  #expect(coverage["documentKind"] as? String == "cuj-state-coverage")
  #expect(coverage["stateFamily"] as? String == "cuj-state")
  #expect(coverage["coverageStatus"] as? String == "pass")
  #expect(requiredStateIDs.count == 2)
  #expect(coveredStateIDs == requiredStateIDs)
  #expect(uncoveredStateIDs.isEmpty)
  #expect(unknownStateIDs.isEmpty)
  #expect(duplicateProofStateIDs.isEmpty)
  #expect(requiredStateIDs.allSatisfy { proofStateIDs.contains($0) })
}

@Test("CUJ-09 product definition contract precedes build work")
func productDefinitionContractPrecedesBuildWork() throws {
  let productDefinition = try readString(relativePath: "release/v0.0.1/product-definition.md")
  let prd = try readString(relativePath: "release/v0.0.1/prd.md")
  let prdReview = try readString(relativePath: "release/v0.0.1/prd-review-session.md")
  let cuj = try readString(relativePath: "release/v0.0.1/cuj.md")
  let why = try readString(relativePath: "release/v0.0.1/why-vaporize.md")
  let claims = try readString(relativePath: "release/v0.0.1/performance-marketing-claims.md")
  let audiencePacket = try readString(relativePath: "release/v0.0.1/evidence/audience-packet.su.json")
  let publicBrochure = try readString(relativePath: "release/v0.0.1/public-brochure.md")
  let publicBrochureHTML = try readString(relativePath: "release/v0.0.1/public-brochure.html")
  let userManual = try readString(relativePath: "release/v0.0.1/user-manual.md")
  let publicChangelog = try readString(relativePath: "release/v0.0.1/public-changelog.md")
  let gates = try readString(relativePath: "release/v0.0.1/release-gates.md")
  let engineeringDocs = try readString(relativePath: "vaporize.engineering.docc/index.md")
  let featureCatalog = try readString(relativePath: "vaporize.engineering.docc/feature-catalog.md")
  let releaseDoctor = try readString(relativePath: "vaporize.engineering.docc/release-doctor.md")
  let resourceBundleDoc = try readString(relativePath: "vaporize.engineering.docc/swiftpm-cli-resource-bundle-installs.md")
  let productProvingGroundDoc = try readString(relativePath: "vaporize.engineering.docc/product-proving-grounds.md")
  let modularity = try readString(relativePath: "vaporize.engineering.docc/modularity-and-ownership-boundaries.md")
  let modificationDiscipline = try readString(relativePath: "vaporize.engineering.docc/vaporware-modification-request-discipline.md")

  #expect(productDefinition.contains("## Product Definition"))
  #expect(productDefinition.contains("## Primary Users"))
  #expect(productDefinition.contains("## Product-Level User Journeys"))
  #expect(productDefinition.contains("## Why Users Choose Vaporize"))
  #expect(productDefinition.contains("## When Not To Choose Vaporize"))
  #expect(productDefinition.contains("## Build Implications"))
  #expect(productDefinition.contains("engineering pedigree"))
  #expect(productDefinition.contains("Future Vaporize features must trace to this product definition"))
  #expect(productDefinition.contains("PRD review session"))
  #expect(productDefinition.contains("Engineering, QA, and Marketing"))
  #expect(prd.contains("FR-022"))
  #expect(prd.contains("FR-025"))
  #expect(prd.contains("FR-026"))
  #expect(prd.contains("FR-027"))
  #expect(prd.contains("FR-028"))
  #expect(prd.contains("FR-029"))
  #expect(prd.contains("FR-030"))
  #expect(prd.contains("FR-031"))
  #expect(prd.contains("FR-032"))
  #expect(prd.contains("FR-033"))
  #expect(prd.contains("FR-VAPORIZE-RUNTIME-SAMPLE-SERIES-APPLE-ARTIFACT-INGESTION"))
  #expect(prdReview.contains("Decision: `GO-WITH-NOTES`"))
  #expect(prdReview.contains("Engineering, QA, and Marketing"))
  #expect(cuj.contains("Product-Level User Journey Map"))
  #expect(cuj.contains("CUJ-17"))
  #expect(cuj.contains("CUJ-18"))
  #expect(cuj.contains("CUJ-19"))
  #expect(cuj.contains("CUJ-20"))
  #expect(cuj.contains("CUJ-21"))
  #expect(cuj.contains("CUJ-22"))
  #expect(cuj.contains("CUJ-23"))
  #expect(why.contains("product-definition.md"))
  #expect(why.contains("engineering pedigree"))
  #expect(why.contains("vaporize-runtime-samples"))
  #expect(why.contains("SwiftPM coverage JSON/profile data"))
  #expect(why.contains("per-feature-flag size"))
  #expect(why.contains("warm/missing"))
  #expect(claims.contains("trace to `product-definition.md`"))
  #expect(claims.contains("Kura runtime sample"))
  #expect(claims.contains("Engineering pedigree"))
  #expect(claims.contains("feature-flag size"))
  #expect(claims.contains("public-brochure.md"))
  #expect(claims.contains("user-manual.md"))
  #expect(claims.contains("public-changelog.md"))
  #expect(audiencePacket.contains("AudienceProfileStackModel"))
  #expect(audiencePacket.contains("external-technical-evaluator"))
  #expect(audiencePacket.contains("future-customer"))
  #expect(audiencePacket.contains("board-approved-public-reader"))
  #expect(audiencePacket.contains("discredulous"))
  #expect(audiencePacket.contains("not approved for publication"))
  #expect(audiencePacket.contains("Carrie CMO"))
  #expect(audiencePacket.contains("cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org"))
  #expect(audiencePacket.contains("Sparkle appcast generation, update signing, or public update delivery"))
  #expect(publicBrochure.contains("external public disclosure surface"))
  #expect(publicBrochure.contains("Feature Brochure"))
  #expect(publicBrochure.contains("Carrie CMO"))
  #expect(publicBrochure.contains("cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org"))
  #expect(publicBrochure.contains("public-brochure.html"))
  #expect(publicBrochure.contains("audience-packet.su.json"))
  #expect(publicBrochure.contains("user-manual.md"))
  #expect(publicBrochure.contains("releaseIdentity"))
  #expect(publicBrochure.contains("Sparkle"))
  #expect(publicBrochure.contains("Claims Not Yet Allowed"))
  #expect(publicBrochure.contains("public-changelog.md"))
  #expect(userManual.contains("## Brochure Companion Contract"))
  #expect(userManual.contains("## Quick Start"))
  #expect(userManual.contains("## Core Commands"))
  #expect(userManual.contains("ReleaseIdentity And Sparkle Boundary"))
  #expect(userManual.contains("Carrie CMO"))
  #expect(userManual.contains("cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org"))
  #expect(userManual.contains("evidence/audience-packet.su.json"))
  #expect(publicBrochureHTML.contains("Build proof for assistant-run software work"))
  #expect(publicBrochureHTML.contains("public-disclosure draft; Carrie CMO gate owner; not approved for publication"))
  #expect(publicBrochureHTML.contains("Carrie CMO"))
  #expect(publicBrochureHTML.contains("cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org"))
  #expect(publicBrochureHTML.contains("Tool release identity"))
  #expect(publicBrochureHTML.contains("releaseIdentity"))
  #expect(publicBrochureHTML.contains("Sparkle Info.plist keys"))
  #expect(publicBrochureHTML.contains("Claims not yet allowed"))
  #expect(publicBrochureHTML.contains("141/141"))
  #expect(publicBrochureHTML.contains("GATE-38"))
  #expect(publicBrochureHTML.contains("evidence/launch-review-packet.json"))
  #expect(publicBrochureHTML.contains("evidence/audience-packet.su.json"))
  #expect(publicBrochureHTML.contains("user-manual.md"))
  #expect(publicChangelog.contains("external release-note companion"))
  #expect(publicChangelog.contains("public-brochure.html"))
  #expect(publicChangelog.contains("Carrie CMO"))
  #expect(publicChangelog.contains("cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org"))
  #expect(publicChangelog.contains("audience-packet.su.json"))
  #expect(publicChangelog.contains("user-manual.md"))
  #expect(publicChangelog.contains("GATE-38-public-disclosure-surfaces"))
  #expect(publicChangelog.contains("Not Publicly Claimed"))
  #expect(gates.contains("GATE-26"))
  #expect(gates.contains("GATE-27"))
  #expect(gates.contains("GATE-30"))
  #expect(gates.contains("GATE-31"))
  #expect(gates.contains("GATE-32"))
  #expect(gates.contains("GATE-33"))
  #expect(gates.contains("GATE-34"))
  #expect(gates.contains("GATE-35"))
  #expect(gates.contains("GATE-36"))
  #expect(gates.contains("GATE-37"))
  #expect(gates.contains("GATE-38"))
  #expect(gates.contains("GATE-39"))
  #expect(gates.contains("GATE-40"))
  #expect(gates.contains("public-brochure.html"))
  #expect(gates.contains("audience-packet.su.json"))
  #expect(gates.contains("user-manual.md"))
  #expect(gates.contains("public-brochure.md"))
  #expect(gates.contains("public-changelog.md"))
  #expect(gates.contains("Every brochure must have an audience packet and user manual"))
  #expect(gates.contains("owning bead"))
  #expect(gates.contains("Carrie CMO"))
  #expect(gates.contains("cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org"))
  #expect(engineeringDocs.contains("wrkstrm.com/engineering"))
  #expect(engineeringDocs.contains("The package-local engineering catalog explains the system. The release packet"))
  #expect(engineeringDocs.contains("pre-code-prd-review"))
  #expect(engineeringDocs.contains("feature-catalog"))
  #expect(engineeringDocs.contains("modularity-and-ownership-boundaries"))
  #expect(engineeringDocs.contains("vaporware-modification-request-discipline"))
  #expect(engineeringDocs.contains("cuj-state-testing-methodology"))
  #expect(engineeringDocs.contains("product-proving-grounds"))
  #expect(engineeringDocs.contains("release-doctor"))
  #expect(featureCatalog.contains("canonical human-readable feature list"))
  #expect(featureCatalog.contains("SwiftPM CLI lifecycle"))
  #expect(featureCatalog.contains("Apple app lifecycle"))
  #expect(featureCatalog.contains("CommonProcess invocation"))
  #expect(featureCatalog.contains("Xcode-selected Swift toolchain"))
  #expect(featureCatalog.contains("Shared Xcode workspace product cache"))
  #expect(featureCatalog.contains("Target feature inspection"))
  #expect(featureCatalog.contains("Feature-scoped test lifecycle"))
  #expect(featureCatalog.contains("Pre-code PRD review"))
  #expect(featureCatalog.contains("Release doctor"))
  #expect(featureCatalog.contains("Project target discovery"))
  #expect(featureCatalog.contains("Workspace product-cache discovery"))
  #expect(featureCatalog.contains("Xcode workspace scheme listing"))
  #expect(featureCatalog.contains("CUJ-state coverage"))
  #expect(featureCatalog.contains("SwiftPM CLI resource-bundle installs"))
  #expect(featureCatalog.contains("Vaporware product proving grounds"))
  #expect(featureCatalog.contains("correct ownership home"))
  #expect(resourceBundleDoc.contains("Bundle.module"))
  #expect(resourceBundleDoc.contains("experimental-install"))
  #expect(resourceBundleDoc.contains("Info.plist"))
  #expect(resourceBundleDoc.contains("VaporizeCUJ22ResourceCLIInstallTests"))
  #expect(releaseDoctor.contains("release-spine self-audit command"))
  #expect(releaseDoctor.contains("vaporware scaffold"))
  #expect(releaseDoctor.contains("CUJ-state coverage"))
  #expect(releaseDoctor.contains("product proving-ground coverage"))
  #expect(releaseDoctor.contains("not a release approval"))
  #expect(productProvingGroundDoc.contains("proving-ground passport"))
  #expect(productProvingGroundDoc.contains("cold-start-chamber"))
  #expect(productProvingGroundDoc.contains("inspection-bay"))
  #expect(productProvingGroundDoc.contains("VaporizeCUJ23ProductProvingGroundTests"))
  #expect(modularity.contains("Capabilities that are genuinely Swift Universal belong in `swift-universal`"))
  #expect(modularity.contains("Apple-bounded, Xcode-bounded, app-bounded"))
  #expect(modularity.contains("SwiftCLIInstaller"))
  #expect(modularity.contains("VaporizeCLI"))
  #expect(modularity.contains("Split `VaporizeCLI` command-family implementations out of `main.swift`"))
  #expect(modificationDiscipline.contains("A vaporware modification request is release work"))
  #expect(modificationDiscipline.contains("A vaporware feature request is product input"))
  #expect(modificationDiscipline.contains("Vaporware modification requests are what assistants execute"))
  #expect(modificationDiscipline.contains("future hardware or other material-domain request families"))
  #expect(modificationDiscipline.contains("vaporware scaffold"))
  #expect(modificationDiscipline.contains("feature-request"))
  #expect(modificationDiscipline.contains("Create or attach to a named feature flag"))
  #expect(modificationDiscipline.contains("Create or attach to an owning bead"))
  #expect(modificationDiscipline.contains("beadTrackingRefs"))
  #expect(modificationDiscipline.contains("Add or update targetable tests"))
  #expect(modificationDiscipline.contains("Update release evidence"))
}

@Test("CUJ-09 release gates keep Pkl generation blocked")
func releaseGatesKeepPklGenerationBlocked() throws {
  let gates = try String(
    contentsOf: packageRoot.appendingPathComponent("release/v0.0.1/release-gates.md"),
    encoding: .utf8
  )

  #expect(gates.contains("BLOCKED-FOR-INTERNAL-ESSENTIAL-RELEASE"))
  #expect(gates.contains("Pkl project generation"))
  #expect(gates.contains("cuj-test-coverage.json"))
  #expect(gates.contains("cuj-state-coverage.json"))
  #expect(gates.contains("launch-review-blocker-disposition.json"))
  #expect(gates.contains("why-vaporize.md"))
  #expect(gates.contains("performance-marketing-claims.md"))
  #expect(gates.contains("public-brochure.html"))
  #expect(gates.contains("audience-packet.su.json"))
  #expect(gates.contains("user-manual.md"))
  #expect(gates.contains("public-brochure.md"))
  #expect(gates.contains("public-changelog.md"))
}

private let packageRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func readJSONObject(relativePath: String) throws -> [String: Any] {
  let data = try Data(contentsOf: packageRoot.appendingPathComponent(relativePath))
  let object = try JSONSerialization.jsonObject(with: data)
  return try #require(object as? [String: Any])
}

private func readString(relativePath: String) throws -> String {
  try String(
    contentsOf: packageRoot.appendingPathComponent(relativePath),
    encoding: .utf8
  )
}
