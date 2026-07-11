import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-26 parses the canonical proof-ledger output path")
func parsesProofLedgerPath() throws {
  let command = try VaporizeCLI.parse([
    "cuj-audit",
    "--path", "/tmp/substrate",
    "--proof-ledger-path", "/saved/cuj-automated-proof-ledger.su.json",
  ])

  #expect(command.mode == .cujAudit)
  #expect(command.proofLedgerPath == "/saved/cuj-automated-proof-ledger.su.json")
}

@Test("CUJ-26 resolves a declared Swift Testing proof in its owning package")
func resolvesDeclaredExecutableProof() throws {
  let fixture = try makeProofFixture(named: "resolved-proof")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeProofPackage(to: fixture, typeName: "AlphaProofTests", methodName: "launches")
  try writeProofCUJ(
    to: fixture,
    id: "cuj-alpha-launch",
    status: 2,
    typeName: "AlphaProofTests",
    methodName: "launches",
    includeProof: true,
    includeLastProven: false
  )

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let definition = try #require(result.definitions.first { $0.id == "cuj-alpha-launch" })
  let entry = try #require(
    CUJAutomatedProofLedgerBuilder.makeReceipt(from: result, vaporizeVersion: "test")
      .entries.first { $0.definitionID == "cuj-alpha-launch" }
  )

  #expect(
    definition.resolvedExecutableProofPaths == [
      "collectives/wrkstrm-core/private/apple/spm/alpha/Tests/AlphaProofTests.swift"
    ])
  #expect(entry.proofState == .executableBound)
  #expect(entry.obligations.map(\.kind) == [.captureGreenReceipt])
}

@Test("CUJ-26 requires saved green evidence before strict proven status")
func rejectsProofPointerWithoutGreenEvidence() throws {
  let fixture = try makeProofFixture(named: "invalid-proven")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeProofPackage(to: fixture, typeName: "AlphaProofTests", methodName: "launches")
  try writeProofCUJ(
    to: fixture,
    id: "cuj-alpha-launch",
    status: 3,
    typeName: "AlphaProofTests",
    methodName: "launches",
    includeProof: true,
    includeLastProven: true
  )
  try writeText(
    "{\"kind\":\"scenario-receipt\",\"cuj\":\"cuj-alpha-launch\",\"verdict\":\"partial\",\"exitCode\":0}",
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/proving-grounds/alpha/cuj-receipts/cuj-alpha-launch.scenario-receipt.su.json"
    )
  )

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let definition = try #require(result.definitions.first)
  let entry = try #require(
    CUJAutomatedProofLedgerBuilder.makeReceipt(from: result, vaporizeVersion: "test").entries.first
  )

  #expect(!definition.isProven)
  #expect(definition.savedEvidencePaths.isEmpty)
  #expect(definition.structuralIssues.contains { $0.contains("saved green") })
  #expect(entry.proofState == .invalidProvenClaim)
  #expect(entry.obligations.contains { $0.kind == .captureGreenReceipt })
}

@Test("CUJ-26 records strict proven status only with executable proof receipt and chronon")
func recordsStrictProvenState() throws {
  let fixture = try makeProofFixture(named: "strict-proven")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeProofPackage(to: fixture, typeName: "AlphaProofTests", methodName: "launches")
  try writeProofCUJ(
    to: fixture,
    id: "cuj-alpha-launch",
    status: 3,
    typeName: "AlphaProofTests",
    methodName: "launches",
    includeProof: true,
    includeLastProven: true
  )
  try writeText(
    "{\"kind\":\"scenario-receipt\",\"cuj\":\"cuj-alpha-launch\",\"verdict\":\"pass\"}",
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/proving-grounds/alpha/cuj-receipts/cuj-alpha-launch.scenario-receipt.su.json"
    )
  )

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let definition = try #require(result.definitions.first { $0.id == "cuj-alpha-launch" })
  let ledger = CUJAutomatedProofLedgerBuilder.makeReceipt(from: result, vaporizeVersion: "test")
  let entry = try #require(ledger.entries.first { $0.definitionID == "cuj-alpha-launch" })

  #expect(definition.isProven)
  #expect(entry.proofState == .proven)
  #expect(entry.obligations.isEmpty)
  #expect(ledger.summary.byProofState["proven"] == 1)
}

@Test("CUJ-26 emits explicit obligations for an unbound journey")
func emitsProofObligations() throws {
  let fixture = try makeProofFixture(named: "proof-obligations")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeProofCUJ(
    to: fixture,
    id: "cuj-alpha-launch",
    status: 1,
    typeName: "AlphaProofTests",
    methodName: "launches",
    includeProof: false,
    includeLastProven: false
  )

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let ledger = CUJAutomatedProofLedgerBuilder.makeReceipt(
    from: result,
    vaporizeVersion: "test",
    generatedAt: Date(timeIntervalSince1970: 0)
  )
  let entry = try #require(ledger.entries.first)
  let encoded = try CUJAutomatedProofLedgerRenderer.renderJSON(
    result,
    vaporizeVersion: "test",
    generatedAt: Date(timeIntervalSince1970: 0)
  )
  let decoded = try JSONDecoder().decode(CUJAutomatedProofLedgerReceipt.self, from: encoded)

  #expect(entry.proofState == .missingBinding)
  #expect(
    Set(entry.obligations.map(\.kind))
      == Set([
        .declareProofReference, .resolveExecutableProof, .captureGreenReceipt,
      ]))
  #expect(decoded.canonicalHome == CUJAutomatedProofLedgerReceipt.canonicalLedgerHome)
  #expect(decoded.summary.definitionCount == 1)
  #expect(decoded.summary.obligationCount == 3)
}

private func makeProofFixture(named name: String) throws -> URL {
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-26-\(name)-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}

private func writeProofPackage(to fixture: URL, typeName: String, methodName: String) throws {
  try writeText(
    "// swift-tools-version: 6.4\nimport PackageDescription\nlet package = Package(name: \"alpha\")\n",
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/spm/alpha/Package.swift"
    )
  )
  try writeText(
    "import Testing\nstruct \(typeName) { @Test func \(methodName)() {} }\n",
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/spm/alpha/Tests/AlphaProofTests.swift"
    )
  )
}

private func writeProofCUJ(
  to fixture: URL,
  id: String,
  status: Int,
  typeName: String,
  methodName: String,
  includeProof: Bool,
  includeLastProven: Bool
) throws {
  let proof =
    includeProof
    ? """
    [{
      "c":"Alpha launches",
      "l":{"tg":[{"k":"vr","v":"alpha","vr":"collectives/wrkstrm-core/private/apple/spm/alpha"}]},
      "tN":"\(typeName)",
      "mN":"\(methodName)",
      "tg":"cuj.alpha.launch"
    }]
    """
    : "[]"
  let lastProven = includeLastProven ? ",\"lP\":1783700000000000000" : ""
  try writeText(
    """
    {
      "CUJModel":"0.1.0",
      "i":"\(id)",
      "t":"Alpha launch",
      "s":"Alpha launch journey",
      "c":1783700000000000000,
      "k":1,
      "st":\(status),
      "a":{"p":"operator"},
      "g":"Launch Alpha",
      "sg":[{"n":1,"a":"Launch"}],
      "cs":"Alpha launched",
      "ap":\(proof)\(lastProven)
    }
    """,
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm/private/universal/kura-spaces/product-lines/alpha/cujs/\(id).cuj.su.json"
    )
  )
}

private func writeText(_ text: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try text.write(to: url, atomically: true, encoding: .utf8)
}
