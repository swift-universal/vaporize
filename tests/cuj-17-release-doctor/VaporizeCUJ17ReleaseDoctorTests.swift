import ArgumentParser
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-17 parses release-doctor CLI arguments")
func parsesReleaseDoctorCLIArguments() throws {
  let command = try VaporizeCLI.parse([
    "release-doctor",
    "--path",
    "/workspace/vaporize",
    "--format",
    "json",
    "--receipt-path",
    "/tmp/release-doctor.receipt.json",
  ])

  #expect(command.mode == .releaseDoctor)
  #expect(command.vaporScanPath == "/workspace/vaporize")
  #expect(command.vaporOutputFormat == .json)
  #expect(command.receiptPath == "/tmp/release-doctor.receipt.json")
}

@Test("CUJ-17 release doctor passes the live Vaporize release spine")
func releaseDoctorPassesLiveReleaseSpine() throws {
  let receipt = try VaporizeReleaseDoctor.inspect(
    path: packageRoot.path,
    requestId: "release-doctor-live"
  )

  #expect(receipt.receiptKind == "vaporize-release-doctor")
  #expect(receipt.subjectAppSlug == "vaporize@wrkstrm-core.cli")
  #expect(receipt.subjectReleaseSlug == "v0.0.1")
  #expect(receipt.overallStatus == "pass")
  #expect(receipt.failedCheckCount == 0)
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-33" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-release-doctor-test-bundle" && $0.status == "pass" })
}

@Test("CUJ-17 release doctor can inspect from the release root")
func releaseDoctorResolvesReleaseRoot() throws {
  let receipt = try VaporizeReleaseDoctor.inspect(
    path: packageRoot.appendingPathComponent("release/v0.0.1").path,
    requestId: "release-doctor-release-root"
  )

  #expect(receipt.packageRootPath == packageRoot.path)
  #expect(receipt.releaseRootPath == packageRoot.appendingPathComponent("release/v0.0.1").path)
  #expect(receipt.overallStatus == "pass")
}

@Test("CUJ-17 release doctor reports missing gate as a blocking failure")
func releaseDoctorReportsMissingGate() throws {
  let fixtureRoot = try makeReleaseDoctorFixture(includeGate33: false)
  defer { try? FileManager.default.removeItem(at: fixtureRoot) }

  let receipt = try VaporizeReleaseDoctor.inspect(
    path: fixtureRoot.path,
    requestId: "release-doctor-missing-gate"
  )
  let gateCheck = try #require(receipt.checks.first { $0.name == "launch-review-gate-33" })

  #expect(receipt.overallStatus == "fail")
  #expect(gateCheck.status == "fail")
  #expect(gateCheck.severity == "blocking")
}

@Test("CUJ-17 release doctor rejects paths outside a release spine")
func releaseDoctorRejectsUnresolvedRoot() throws {
  let emptyRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-release-doctor-empty-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: emptyRoot, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: emptyRoot) }

  #expect(throws: ReleaseDoctorError.self) {
    _ = try VaporizeReleaseDoctor.inspect(
      path: emptyRoot.path,
      requestId: "release-doctor-empty"
    )
  }
}

private let packageRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func makeReleaseDoctorFixture(includeGate33: Bool) throws -> URL {
  let packageRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-release-doctor-\(UUID().uuidString)")
  let releaseRoot = packageRoot.appendingPathComponent("release/v0.0.1")

  for path in [
    "release/v0.0.1/product-definition.md",
    "release/v0.0.1/prd.md",
    "release/v0.0.1/prd-review-session.md",
    "release/v0.0.1/cuj.md",
    "release/v0.0.1/release-gates.md",
    "release/v0.0.1/why-vaporize.md",
    "release/v0.0.1/performance-marketing-claims.md",
    "release/v0.0.1/wrkstrm-app-minimums.md",
    "vaporize.engineering.docc/index.md",
    "vaporize.engineering.docc/feature-catalog.md",
    "vaporize.engineering.docc/release-doctor.md",
    "vaporize.engineering.docc/vaporware-modification-request-discipline.md",
    "vaporize.engineering.docc/modularity-and-ownership-boundaries.md",
    "vaporize.engineering.docc/feature-test-lifecycle.md",
  ] {
    let contents: String
    switch path {
    case "release/v0.0.1/product-definition.md":
      contents = "engineering pedigree"
    case "release/v0.0.1/prd.md":
      contents = "FR-027"
    case "release/v0.0.1/cuj.md":
      contents = "CUJ-17"
    case "release/v0.0.1/release-gates.md":
      contents = includeGate33 ? "GATE-33-release-doctor" : "GATE-32"
    case "vaporize.engineering.docc/feature-catalog.md":
      contents = "Release doctor"
    case "vaporize.engineering.docc/vaporware-modification-request-discipline.md":
      contents = "vaporware scaffold feature-request"
    default:
      contents = "fixture"
    }
    try write(contents, to: packageRoot.appendingPathComponent(path))
  }

  let gateResults = includeGate33
    ? #"{"gateRef":"GATE-33-release-doctor","status":"pass","rationale":"fixture"}"#
    : #"{"gateRef":"GATE-32","status":"pass","rationale":"fixture"}"#
  try write(
    """
    {
      "subjectAppSlug": "vaporize@wrkstrm-core.cli",
      "evidenceRefs": [
        { "t": "Release doctor receipt" }
      ],
      "gateResults": [
        \(gateResults)
      ]
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/launch-review-packet.json")
  )

  try write(
    """
    {
      "receiptInventory": [
        { "receiptKind": "vaporize-release-doctor" }
      ]
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/vaporize-v0.0.1-provenance-artifact.json")
  )

  try write(
    """
    {
      "counts": {
        "activeCUJCount": 17,
        "requiredReleaseEvidenceCheckCount": 9,
        "currentExecutableSwiftTestBreakdown": {
          "VaporizeCUJ17ReleaseDoctorTests": 5
        }
      }
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/cuj-test-coverage.json")
  )

  return packageRoot
}

private func write(_ contents: String, to url: URL) throws {
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try Data(contents.utf8).write(to: url)
}
