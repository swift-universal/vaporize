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
    "vaporize.engineering.docc/release-doctor.md",
    "release/v0.0.1/evidence/launch-review-packet.json",
    "release/v0.0.1/evidence/hello-world-google-target-features-inspection.receipt.json",
    "release/v0.0.1/evidence/vaporize-v0.0.1-release-doctor.receipt.json",
    "release/v0.0.1/evidence/creative-selection-v0.2-list-targets.receipt.json",
  ] {
    #expect(FileManager.default.fileExists(atPath: packageRoot.appendingPathComponent(relativePath).path))
  }
}

@Test("CUJ-09 launch-review packet is valid JSON and internal essential")
func launchReviewPacketIsValidJSONAndInternalEssential() throws {
  let packet = try readJSONObject(relativePath: "release/v0.0.1/evidence/launch-review-packet.json")

  #expect(packet["subjectAppSlug"] as? String == "vaporize@wrkstrm-core.cli")
  #expect(packet["subjectWareKindSlug"] as? String == "internal-essential-cli")
  let releaseTarget = try #require(packet["releaseTarget"] as? [String: Any])
  #expect(releaseTarget["toolClassification"] as? String == "internal-essential-tool")
  let gateResults = try #require(packet["gateResults"] as? [[String: Any]])
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
}

@Test("CUJ-09 CUJ coverage contract is valid JSON and names the floor")
func cujCoverageContractIsValidJSONAndNamesTheFloor() throws {
  let coverage = try readJSONObject(relativePath: "release/v0.0.1/evidence/cuj-test-coverage.json")
  let counts = try #require(coverage["counts"] as? [String: Any])

  #expect(counts["activeCUJCount"] as? Int == 18)
  #expect(counts["deferredCUJCount"] as? Int == 1)
  #expect(counts["requiredSwiftTestObligationCount"] as? Int == 79)
  #expect(counts["requiredReleaseEvidenceCheckCount"] as? Int == 10)
  #expect(counts["requiredTargetableTestObligationCount"] as? Int == 89)
  #expect(counts["currentExecutableSwiftTestCount"] as? Int == 97)
}

@Test("CUJ-09 product definition contract precedes build work")
func productDefinitionContractPrecedesBuildWork() throws {
  let productDefinition = try readString(relativePath: "release/v0.0.1/product-definition.md")
  let prd = try readString(relativePath: "release/v0.0.1/prd.md")
  let prdReview = try readString(relativePath: "release/v0.0.1/prd-review-session.md")
  let cuj = try readString(relativePath: "release/v0.0.1/cuj.md")
  let why = try readString(relativePath: "release/v0.0.1/why-vaporize.md")
  let claims = try readString(relativePath: "release/v0.0.1/performance-marketing-claims.md")
  let gates = try readString(relativePath: "release/v0.0.1/release-gates.md")
  let engineeringDocs = try readString(relativePath: "vaporize.engineering.docc/index.md")
  let featureCatalog = try readString(relativePath: "vaporize.engineering.docc/feature-catalog.md")
  let releaseDoctor = try readString(relativePath: "vaporize.engineering.docc/release-doctor.md")
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
  #expect(prd.contains("FR-VAPORIZE-RUNTIME-SAMPLE-SERIES-APPLE-ARTIFACT-INGESTION"))
  #expect(prdReview.contains("Decision: `GO-WITH-NOTES`"))
  #expect(prdReview.contains("Engineering, QA, and Marketing"))
  #expect(cuj.contains("Product-Level User Journey Map"))
  #expect(cuj.contains("CUJ-17"))
  #expect(cuj.contains("CUJ-18"))
  #expect(why.contains("product-definition.md"))
  #expect(why.contains("engineering pedigree"))
  #expect(why.contains("vaporize-runtime-samples"))
  #expect(why.contains("SwiftPM coverage JSON/profile data"))
  #expect(why.contains("per-feature-flag size"))
  #expect(claims.contains("trace to `product-definition.md`"))
  #expect(claims.contains("Kura runtime sample"))
  #expect(claims.contains("Engineering pedigree"))
  #expect(claims.contains("feature-flag size"))
  #expect(gates.contains("GATE-26"))
  #expect(gates.contains("GATE-27"))
  #expect(gates.contains("GATE-30"))
  #expect(gates.contains("GATE-31"))
  #expect(gates.contains("GATE-32"))
  #expect(gates.contains("GATE-33"))
  #expect(gates.contains("GATE-34"))
  #expect(engineeringDocs.contains("wrkstrm.com/engineering"))
  #expect(engineeringDocs.contains("The package-local engineering catalog explains the system. The release packet"))
  #expect(engineeringDocs.contains("pre-code-prd-review"))
  #expect(engineeringDocs.contains("feature-catalog"))
  #expect(engineeringDocs.contains("modularity-and-ownership-boundaries"))
  #expect(engineeringDocs.contains("vaporware-modification-request-discipline"))
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
  #expect(featureCatalog.contains("correct ownership home"))
  #expect(releaseDoctor.contains("release-spine self-audit command"))
  #expect(releaseDoctor.contains("vaporware scaffold"))
  #expect(releaseDoctor.contains("not a release approval"))
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
  #expect(gates.contains("why-vaporize.md"))
  #expect(gates.contains("performance-marketing-claims.md"))
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
