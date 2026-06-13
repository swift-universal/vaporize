import Foundation
import Testing

@Test("CUJ-09 release review artifacts exist")
func releaseReviewArtifactsExist() {
  for relativePath in [
    "release/v0.0.1/prd.md",
    "release/v0.0.1/cuj.md",
    "release/v0.0.1/release-gates.md",
    "release/v0.0.1/why-vaporize.md",
    "release/v0.0.1/evidence/launch-review-packet.json",
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
}

@Test("CUJ-09 CUJ coverage contract is valid JSON and names the floor")
func cujCoverageContractIsValidJSONAndNamesTheFloor() throws {
  let coverage = try readJSONObject(relativePath: "release/v0.0.1/evidence/cuj-test-coverage.json")
  let counts = try #require(coverage["counts"] as? [String: Any])

  #expect(counts["activeCUJCount"] as? Int == 15)
  #expect(counts["deferredCUJCount"] as? Int == 2)
  #expect(counts["requiredTargetableTestObligationCount"] as? Int == 68)
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
