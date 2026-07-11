import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-25 parses a saved portfolio audit request")
func parsesSavedPortfolioAuditRequest() throws {
  let command = try VaporizeCLI.parse([
    "cuj-audit",
    "--path", "/tmp/substrate",
    "--format", "json",
    "--receipt-path", "/tmp/cuj-audit.json",
    "--report-path", "/tmp/cuj-audit.md",
  ])

  #expect(command.mode == .cujAudit)
  #expect(command.vaporScanPath == "/tmp/substrate")
  #expect(command.vaporOutputFormat == .json)
  #expect(command.receiptPath == "/tmp/cuj-audit.json")
  #expect(command.reportPath == "/tmp/cuj-audit.md")
}

@Test("CUJ-25 separates definitions matrices receipts fixtures and tests")
func separatesDefinitionsMatricesReceiptsFixturesAndTests() throws {
  let fixture = try makeFixtureDirectory(named: "artifact-classes")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeText(
    packageManifest(named: "alpha"),
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/apps/alpha/Package.swift"
    )
  )
  try writeText(
    compactCUJ(id: "cuj-alpha-launch", status: 2, withProof: true),
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm/private/universal/kura-spaces/product-lines/alpha/cujs/cuj-alpha-launch.cuj.su.json"
    )
  )
  try FileManager.default.createDirectory(
    at: fixture.appendingPathComponent(
      "collectives/wrkstrm/private/universal/kura-spaces/product-lines/beta"
    ),
    withIntermediateDirectories: true
  )
  try FileManager.default.createDirectory(
    at: fixture.appendingPathComponent(
      "clients/acme/private/universal/product-lines/acme-product"
    ),
    withIntermediateDirectories: true
  )
  try writeText(
    compactCUJ(id: "cuj-acme-launch", status: 2, withProof: true),
    to: fixture.appendingPathComponent(
      "clients/acme/private/universal/kura-spaces/cujs/cuj-acme-launch.cuj.json"
    )
  )
  try writeText(
    """
    {
      "CUJCoverageMatrixModel": "0.1.0",
      "kind": "cuj-coverage-matrix",
      "cujs": [
        {
          "id": "cuj-vapor-wares-acquire",
          "title": "Acquire a ware",
          "acceptanceSteps": ["Acquire"],
          "currentEvidence": "test passes",
          "receiptPath": "cuj-receipts/cuj-vapor-wares-acquire.scenario-receipt.su.json",
          "latestVerdict": "pass"
        }
      ]
    }
    """,
    to: fixture.appendingPathComponent(
      "collectives/vapor-wares-org/proving-grounds/vapor-wares/launch-review/cuj-coverage-matrix.su.json"
    )
  )
  try writeText(
    "{\"kind\":\"scenario-receipt\",\"scenario\":\"cuj-vapor-wares-acquire\",\"verdict\":\"pass\"}",
    to: fixture.appendingPathComponent(
      "collectives/vapor-wares-org/proving-grounds/vapor-wares/launch-review/cuj-receipts/cuj-vapor-wares-acquire.scenario-receipt.su.json"
    )
  )
  try writeText(
    compactCUJ(id: "cuj-schema-example", status: 1, withProof: false),
    to: fixture.appendingPathComponent(
      "collectives/schema-universal/schema-families/cuj-schemas/fixtures/canonical.cuj-schema-example.json"
    )
  )
  try writeText(
    """
    import Testing
    @Test("cuj-vapor-wares-acquire") func provesAcquisition() {}
    """,
    to: fixture.appendingPathComponent(
      "collectives/vapor-wares-org/private/apple/apps/vapor-wares/Tests/VaporWaresCUJTests.swift"
    )
  )
  try writeText(
    "{\"kind\":\"bead\",\"slug\":\"cuj-gap\"}",
    to: fixture.appendingPathComponent("collectives/clia-org/beads/cuj-gap.beads-issue.json")
  )
  try writeText(
    "{\"kind\":\"workflow-series\",\"id\":\"cuj\"}",
    to: fixture.appendingPathComponent(
      "collectives/spaces-universal/private/universal/kura-spaces/workflows/cuj/cuj.workflow-series.json"
    )
  )
  try writeText(
    "{\"type\":\"object\"}",
    to: fixture.appendingPathComponent(
      "collectives/schema-universal/schema-families/cuj-schemas/schemas/cuj.schema.json"
    )
  )

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)

  #expect(result.summary.uniqueDefinitionCount == 3)
  #expect(result.summary.standaloneTypedDefinitionCount == 2)
  #expect(result.summary.matrixDefinitionCount == 1)
  #expect(result.summary.proofBoundDefinitionCount == 3)
  #expect(result.summary.canonicalProductHomeCount == 3)
  #expect(result.summary.canonicalProductHomesWithDirectDefinitions == 1)
  #expect(result.summary.canonicalProductHomesWithLinkedOnlyDefinitions == 1)
  #expect(result.summary.canonicalProductHomesWithDefinitions == 2)
  #expect(result.summary.canonicalProductHomesWithoutDefinitions == 1)
  #expect(result.summary.activeOwnedSurfaceCount == 1)
  #expect(result.summary.activeOwnedImplementationProjectsWithCUJs == 1)
  #expect(result.summary.byArtifactClass["schema-fixture"] == 1)
  #expect(result.summary.byArtifactClass["coverage-matrix"] == 1)
  #expect(result.summary.byArtifactClass["coverage-receipt"] == 1)
  #expect(result.summary.byArtifactClass["test-proof"] == 1)
  #expect(result.summary.byArtifactClass["bead-reference"] == 1)
  #expect(result.summary.byArtifactClass["workflow-support"] == 1)
  #expect(result.summary.byArtifactClass["schema-definition"] == 1)
  #expect(result.summary.byArtifactClass["unknown-cuj-artifact"] == nil)

  let alpha = try #require(result.definitions.first { $0.id == "cuj-alpha-launch" })
  #expect(!alpha.isProven)
  #expect(alpha.structuralIssues.isEmpty)
  let beta = try #require(result.projects.first { $0.name == "beta" })
  #expect(beta.definitionIDs.isEmpty)
  let acme = try #require(result.projects.first { $0.name == "acme-product" })
  #expect(acme.directDefinitionIDs.isEmpty)
  #expect(acme.linkedDefinitionIDs == ["cuj-acme-launch"])
}

@Test("CUJ-25 retains legacy multi-journey JSON and Markdown as definitions")
func retainsLegacyJSONAndMarkdownDefinitions() throws {
  let fixture = try makeFixtureDirectory(named: "legacy-definitions")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeText(
    """
    {
      "kind": "cuj",
      "criticalUserJourneys": [
        {"cujID":"CUJ-LEGACY-001","title":"First","steps":["one"]},
        {"cujID":"CUJ-LEGACY-002","title":"Second","steps":["one","two"]}
      ]
    }
    """,
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/apps/legacy/agenda/legacy.cuj.json"
    )
  )
  try writeText(
    """
    # Release Journeys

    ## CUJ-31 - Operator opens the app

    The operator opens it.

    ## CUJ-32 - Operator closes the app

    The operator closes it.
    """,
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/spm/legacy-cli/release/v0.1.0/cuj.md"
    )
  )
  try writeText(
    """
    {
      "CUJModel":"0.0.1-untyped",
      "slug":"cuj-legacy-bring-to-front",
      "title":"Bring a panel to front",
      "goal":"Reach the covered panel",
      "desiredFlow":[{"step":1,"action":"Click the panel"}]
    }
    """,
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-core/private/apple/apps/legacy/cujs/cuj-legacy-bring-to-front.cuj.json"
    )
  )
  try writeText(
    """
    {
      "cujs":[
        {
          "id":"cuj-city-orbit",
          "journey":"Orbit the city",
          "steps":["Drag"],
          "verification":"automated"
        }
      ]
    }
    """,
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm-worlds/private/campus/zoo/data-city.mac.app/data-city-cuj.manifest.json"
    )
  )

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)

  #expect(
    Set(result.definitions.map(\.id))
      == Set([
        "CUJ-LEGACY-001", "CUJ-LEGACY-002", "CUJ-31", "CUJ-32",
        "cuj-legacy-bring-to-front", "cuj-city-orbit",
      ]))
  #expect(result.summary.legacyDefinitionCount == 6)
  #expect(result.summary.standaloneTypedDefinitionCount == 0)
  #expect(result.summary.byArtifactClass["legacy-json-definition"] == 3)
  #expect(result.summary.byArtifactClass["legacy-markdown-definition"] == 1)
}

@Test("CUJ-25 reports malformed proven records without counting them as proof")
func reportsMalformedProvenRecords() throws {
  let fixture = try makeFixtureDirectory(named: "malformed-proven")
  defer { try? FileManager.default.removeItem(at: fixture) }

  try writeText(
    compactCUJ(id: "cuj-broken-proven", status: 3, withProof: false),
    to: fixture.appendingPathComponent(
      "collectives/wrkstrm/private/universal/kura-spaces/product-lines/broken/cujs/cuj-broken-proven.cuj.su.json"
    )
  )

  let result = try CUJPortfolioAuditScanner().scan(path: fixture.path)
  let definition = try #require(result.definitions.first)
  let report = CUJPortfolioAuditRenderer.renderMarkdown(result)

  #expect(!definition.proofBound)
  #expect(!definition.isProven)
  #expect(definition.structuralIssues.contains { $0.contains("automated proofs") })
  #expect(definition.structuralIssues.contains { $0.contains("last-proven") })
  #expect(result.summary.structurallyInvalidDefinitionCount == 1)
  #expect(report.contains("cuj-broken-proven"))
  #expect(report.contains("Zero-CUJ Product Homes") == false)
}

private func compactCUJ(id: String, status: Int, withProof: Bool) -> String {
  let proofs =
    withProof
    ? "[{\"c\":\"launches\",\"l\":{},\"tN\":\"LaunchTests\",\"mN\":\"launches\"}]"
    : "[]"
  let lastProven = withProof ? ",\"lP\":1783700000000000000" : ""
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
      "g":"Complete the fixture journey",
      "sg":[{"n":1,"a":"Act"}],
      "cs":"Complete",
      "ap":\(proofs)\(lastProven)
    }
    """
}

private func packageManifest(named name: String) -> String {
  """
  // swift-tools-version: 6.4
  import PackageDescription
  let package = Package(name: "\(name)")
  """
}

private func makeFixtureDirectory(named name: String) throws -> URL {
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-25-\(name)-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}

private func writeText(_ text: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try text.write(to: url, atomically: true, encoding: .utf8)
}
