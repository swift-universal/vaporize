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
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-34" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-35" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-36" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-release-doctor-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-project-target-discovery-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-workspace-cache-discovery-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-xcode-workspace-scheme-listing-test-bundle" && $0.status == "pass" })
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
      contents = "FR-027 FR-028 FR-029 FR-030"
    case "release/v0.0.1/cuj.md":
      contents = "CUJ-17 CUJ-18 CUJ-19 CUJ-20"
    case "release/v0.0.1/release-gates.md":
      contents = includeGate33
        ? "GATE-33-release-doctor GATE-34-project-target-discovery GATE-35-workspace-product-cache-discovery GATE-36-xcode-workspace-scheme-listing"
        : "GATE-32 GATE-34-project-target-discovery GATE-35-workspace-product-cache-discovery GATE-36-xcode-workspace-scheme-listing"
    case "vaporize.engineering.docc/feature-catalog.md":
      contents = "Release doctor Project target discovery Workspace product-cache discovery Xcode workspace scheme listing"
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
        { "t": "Release doctor receipt" },
        { "t": "Creative Selection v0.2 target discovery receipt" },
        { "t": "Creative Selection v0.2 workspace cache discovery receipt" }
      ],
      "gateResults": [
        \(gateResults),
        { "gateRef": "GATE-34-project-target-discovery", "status": "pass", "rationale": "fixture" },
        { "gateRef": "GATE-35-workspace-product-cache-discovery", "status": "pass", "rationale": "fixture" },
        { "gateRef": "GATE-36-xcode-workspace-scheme-listing", "status": "pass", "rationale": "fixture" }
      ]
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/launch-review-packet.json")
  )

  try write(
    """
    {
      "receiptInventory": [
        { "receiptKind": "vaporize-release-doctor" },
        { "receiptKind": "vaporize-project-target-discovery" },
        {
          "receiptKind": "vaporize-project-target-discovery",
          "claim": "fixture workspace product-cache candidate discovery"
        }
      ]
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/vaporize-v0.0.1-provenance-artifact.json")
  )

  try write(
    """
    {
      "counts": {
        "activeCUJCount": 20,
        "requiredReleaseEvidenceCheckCount": 11,
        "currentExecutableSwiftTestBreakdown": {
          "VaporizeCUJ17ReleaseDoctorTests": 5,
          "VaporizeCUJ18ListTargetsTests": 5,
          "VaporizeCUJ19WorkspaceCacheDiscoveryTests": 5,
          "VaporizeCUJ20XcodeWorkspaceSchemesTests": 5
        }
      }
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/cuj-test-coverage.json")
  )

  try write(
    #"{"receiptKind":"vaporize-project-target-discovery"}"#,
    to: releaseRoot.appendingPathComponent("evidence/creative-selection-v0.2-list-targets.receipt.json")
  )

  try write(
    #"{"receiptKind":"vaporize-project-target-discovery","claim":"fixture workspace product-cache candidate discovery"}"#,
    to: releaseRoot.appendingPathComponent("evidence/creative-selection-v0.2-workspace-cache-discovery.receipt.json")
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
