import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-27 parses saved project-ledger JSON and CSV paths")
func parsesProjectLedgerPaths() throws {
  let command = try VaporizeCLI.parse([
    "cuj-audit",
    "--path", "/tmp/substrate",
    "--project-ledger-path", "/saved/cuj-project-coverage.su.json",
    "--project-ledger-csv-path", "/saved/cuj-project-coverage.csv",
  ])

  #expect(command.mode == .cujAudit)
  #expect(command.projectLedgerPath == "/saved/cuj-project-coverage.su.json")
  #expect(command.projectLedgerCSVPath == "/saved/cuj-project-coverage.csv")
}

@Test("CUJ-27 emits one dimensional coverage row per implementation project")
func emitsOneCoverageRowPerImplementationProject() throws {
  let fixture = try makeProjectCoverageFixture()
  defer { try? FileManager.default.removeItem(at: fixture) }

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let ledger = CUJImplementationProjectCoverageLedgerBuilder.makeReceipt(
    from: result,
    vaporizeVersion: "test",
    generatedAt: Date(timeIntervalSince1970: 0)
  )

  #expect(ledger.summary.implementationProjectCount == 3)
  #expect(ledger.summary.implementationSurfaceCount == 3)
  #expect(ledger.projects.count == 3)
  #expect(ledger.summary.mappedProjectCount == 2)
  #expect(ledger.summary.unmappedProjectCount == 1)
  #expect(ledger.summary.projectWithDefinitionCount == 2)
  #expect(ledger.summary.projectQualifiedDefinitionCount == 2)
  #expect(ledger.summary.distinctDefinitionIDCount == 2)
  #expect(ledger.summary.duplicatedDefinitionIDCount == 0)
  #expect(ledger.summary.definitionRecordsUsingDuplicatedIDs == 0)
  #expect(ledger.summary.byNextAction["classify-cuj-applicability"] == 1)

  let alpha = try #require(ledger.projects.first { $0.productLine == "alpha" })
  #expect(alpha.mappingConfidence == .medium)
  #expect(alpha.projectMappings.first?.methods == [.uniqueProductName])
  #expect(alpha.proofLegs.definitionCount == 1)
  #expect(alpha.proofLegs.standaloneTypedDefinitionCount == 1)
  #expect(alpha.proofLegs.declaredBindingDefinitionCount == 1)
  #expect(alpha.proofLegs.executableDefinitionCount == 1)
  #expect(alpha.proofLegs.evidenceBackedDefinitionCount == 0)
  #expect(alpha.proofLegCompletionBasisPoints == 6000)
  #expect(alpha.coverageBand == .executableComplete)
  #expect(alpha.nextActions.contains { $0.kind == .confirmProjectMapping && $0.quantity == 1 })
  #expect(alpha.nextActions.contains { $0.kind == .captureGreenReceipt && $0.quantity == 1 })

  let beta = try #require(ledger.projects.first { $0.productLine == "beta" })
  #expect(beta.mappingConfidence == .unmapped)
  #expect(beta.coverageBand == .unclassifiedNoCUJ)
  #expect(beta.proofLegs.definitionCount == 0)
  #expect(beta.nextActions == [
    CUJImplementationProjectAction(
      kind: .classifyCUJApplicability,
      quantity: 1,
      message:
        "Classify whether this implementation project owns an operator journey or is covered through a consuming product's CUJs."
    )
  ])

  let gamma = try #require(ledger.projects.first { $0.productLine == "gamma" })
  #expect(gamma.mappingConfidence == .high)
  #expect(gamma.projectMappings.first?.methods.contains(.pathOverlap) == true)
  #expect(gamma.coverageBand == .definitionOnly)
  #expect(gamma.definitionObligationCounts["declare-proof-reference"] == 1)
  #expect(gamma.nextActions.contains { $0.kind == .resolveExecutableProof && $0.quantity == 1 })
}

@Test("CUJ-27 CSV retains every project path and proof dimension")
func rendersCompleteProjectCSV() throws {
  let fixture = try makeProjectCoverageFixture()
  defer { try? FileManager.default.removeItem(at: fixture) }

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let csv = CUJImplementationProjectCoverageLedgerRenderer.renderCSV(
    result,
    vaporizeVersion: "test",
    generatedAt: Date(timeIntervalSince1970: 0)
  )
  let lines = csv.split(separator: "\n")

  #expect(lines.count == 4)
  #expect(lines.first?.contains("completionBasisPoints") == true)
  #expect(csv.contains("collectives/wrkstrm-core/private/apple/spm/alpha"))
  #expect(csv.contains("collectives/wrkstrm-core/private/apple/spm/beta"))
  #expect(csv.contains("collectives/wrkstrm-core/private/apple/spm/gamma"))
  #expect(csv.contains("capture-green-receipt:1"))
}

@Test("CUJ-27 project ledger round-trips with rollups and boundaries")
func projectLedgerRoundTrips() throws {
  let fixture = try makeProjectCoverageFixture()
  defer { try? FileManager.default.removeItem(at: fixture) }

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let data = try CUJImplementationProjectCoverageLedgerRenderer.renderJSON(
    result,
    vaporizeVersion: "test",
    generatedAt: Date(timeIntervalSince1970: 0)
  )
  let decoded = try JSONDecoder().decode(
    CUJImplementationProjectCoverageLedgerReceipt.self,
    from: data
  )

  #expect(decoded.ledgerID == "substrate-cuj-implementation-project-coverage-ledger")
  #expect(decoded.projects.count == 3)
  #expect(decoded.summary.byOwner.first { $0.key == "wrkstrm-core" }?.projectCount == 3)
  #expect(decoded.summary.byDomain.first { $0.key == "apple" }?.projectCount == 3)
  #expect(decoded.boundaries.first?.contains("one row") == true)
}

private func makeProjectCoverageFixture() throws -> URL {
  let fixture = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-27-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)

  for name in ["alpha", "beta", "gamma"] {
    try writeProjectCoverageText(
      "// swift-tools-version: 6.4\nimport PackageDescription\nlet package = Package(name: \"\(name)\")\n",
      to: fixture.appendingPathComponent(
        "collectives/wrkstrm-core/private/apple/spm/\(name)/Package.swift"
      )
    )
  }
  try writeProjectCoverageText(
    "import Testing\nstruct AlphaProofTests { @Test func launches() {} }\n",
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/spm/alpha/Tests/AlphaProofTests.swift"
    )
  )
  try writeProjectCoverageText(
    compactProjectCoverageCUJ(
      id: "cuj-alpha-launch",
      proofPackagePath: "collectives/wrkstrm-core/private/apple/spm/alpha"
    ),
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm/private/universal/kura-spaces/product-lines/alpha/cujs/cuj-alpha-launch.cuj.su.json"
    )
  )
  try writeProjectCoverageText(
    compactProjectCoverageCUJ(id: "cuj-gamma-launch", proofPackagePath: nil),
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/spm/gamma/cujs/cuj-gamma-launch.cuj.su.json"
    )
  )
  return fixture
}

private func compactProjectCoverageCUJ(id: String, proofPackagePath: String?) -> String {
  let proof: String
  let status: Int
  if let proofPackagePath {
    status = 2
    proof =
      "[{\"c\":\"Launches\",\"l\":{\"tg\":[{\"k\":\"vr\",\"v\":\"alpha\",\"vr\":\"\(proofPackagePath)\"}]},\"tN\":\"AlphaProofTests\",\"mN\":\"launches\"}]"
  } else {
    status = 1
    proof = "[]"
  }
  return """
    {
      "CUJModel":"0.1.0",
      "i":"\(id)",
      "t":"\(id)",
      "s":"Fixture journey",
      "c":1783700000000000000,
      "k":1,
      "st":\(status),
      "a":{"p":"operator"},
      "g":"Launch",
      "sg":[{"n":1,"a":"Launch"}],
      "cs":"Launched",
      "ap":\(proof)
    }
    """
}

private func writeProjectCoverageText(_ text: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try text.write(to: url, atomically: true, encoding: .utf8)
}
