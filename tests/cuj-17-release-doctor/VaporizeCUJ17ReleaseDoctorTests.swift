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
  #expect(receipt.subjectAppSlug == "vaporize.cli@wrkstrm-core.clia.sh")
  #expect(receipt.subjectReleaseSlug == "v0.0.1")
  #expect(receipt.overallStatus == "pass")
  #expect(receipt.requiredArtifactCount == 28)
  #expect(receipt.checkCount == 149)
  #expect(receipt.failedCheckCount == 0)
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-33" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-34" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-35" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-36" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-37" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-38" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-39" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-40" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-public-brochure-evidence-ref" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-public-brochure-html-evidence-ref" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-audience-packet-evidence-ref" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-user-manual-evidence-ref" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-public-changelog-evidence-ref" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-resource-cli-install-evidence-ref" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-product-proving-ground-evidence-ref" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "public-brochure-html-marketing-site-headline" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "public-brochure-html-disclosure-boundary" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "public-brochure-html-carrie-cmo-owner" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "audience-packet-model" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "audience-packet-publication-boundary" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "audience-packet-carrie-cmo-owner" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "user-manual-brochure-companion-contract" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "user-manual-quick-start" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "user-manual-carrie-cmo-owner" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "gate-brochure-companion-contract" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "gate-vaporware-owning-bead-discipline" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "gate-public-disclosure-carrie-cmo-owner" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "public-brochure-carrie-cmo-owner" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "public-changelog-carrie-cmo-owner" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-carrie-cmo-owner" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-carrie-cmo-not-signed-off" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-human-review-policy" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-approved-gates-have-human-review" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-gate-status-vocabulary" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-known-followups-match-prd" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "launch-review-known-followups-match-release-gates" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "blocker-disposition-human-approval-boundary" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "blocker-disposition-followups-cover-launch-review" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "blocker-disposition-hard-blockers-match-launch-review" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "blocker-disposition-burns-duplicate-blockers" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "blocker-disposition-counts-match-launch-review" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "vaporware-modification-owning-bead-discipline" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "prd-resource-cli-install-requirement" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-resource-cli-install-journey" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "gate-resource-cli-install" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "feature-catalog-resource-cli-install" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "swiftpm-cli-resource-bundle-doc" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "prd-product-proving-ground-requirement" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-product-proving-ground-journey" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-portfolio-audit-journey" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "prd-automated-proof-ledger-requirement" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-automated-proof-ledger-journey" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "gate-product-proving-grounds" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "feature-catalog-product-proving-grounds" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "product-proving-ground-doc" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-yml-pkl-parity-proving-ground-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-yml-pkl-import-proving-ground-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-release-doctor-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-pkl-xcodeproj-graph-scheme-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-project-target-discovery-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-workspace-cache-discovery-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-xcode-workspace-scheme-listing-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-cuj-state-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-resource-cli-install-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-product-proving-ground-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-cuj-portfolio-audit-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "coverage-cuj-automated-proof-ledger-test-bundle" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-state-coverage-status" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-state-proof-floor" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-state-uncovered-empty" && $0.status == "pass" })
  #expect(receipt.checks.contains { $0.name == "cuj-state-unknown-empty" && $0.status == "pass" })
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

@Test("CUJ-17 release doctor rejects approved gates without human review")
func releaseDoctorRejectsApprovedGateWithoutHumanReview() throws {
  let fixtureRoot = try makeReleaseDoctorFixture(includeGate33: true, gateStatus: "PASS")
  defer { try? FileManager.default.removeItem(at: fixtureRoot) }

  let receipt = try VaporizeReleaseDoctor.inspect(
    path: fixtureRoot.path,
    requestId: "release-doctor-unreviewed-gate-pass"
  )
  let humanReviewCheck = try #require(
    receipt.checks.first { $0.name == "launch-review-approved-gates-have-human-review" }
  )

  #expect(receipt.overallStatus == "fail")
  #expect(humanReviewCheck.status == "fail")
  #expect(humanReviewCheck.severity == "blocking")
  #expect(humanReviewCheck.detail.contains("GATE-33-release-doctor"))
}

@Test("CUJ-17 release doctor rejects launch-review follow-up drift")
func releaseDoctorRejectsFollowUpListDrift() throws {
  let fixtureRoot = try makeReleaseDoctorFixture(
    includeGate33: true,
    prdKnownFollowUps: [fixtureFollowUps[0]]
  )
  defer { try? FileManager.default.removeItem(at: fixtureRoot) }

  let receipt = try VaporizeReleaseDoctor.inspect(
    path: fixtureRoot.path,
    requestId: "release-doctor-follow-up-drift"
  )
  let followUpCheck = try #require(
    receipt.checks.first { $0.name == "launch-review-known-followups-match-prd" }
  )

  #expect(receipt.overallStatus == "fail")
  #expect(followUpCheck.status == "fail")
  #expect(followUpCheck.severity == "blocking")
  #expect(followUpCheck.detail.contains(fixtureFollowUps[1]))
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

private let fixtureFollowUps = [
  "FR-VAPORIZE-PKL-PROJECT-GENERATION-move-owned-xcodegen-surfaces-to-pkl",
  "FR-VAPORIZE-AUTO-INCREMENT-BUILD-NUMBERS",
]

private func makeReleaseDoctorFixture(
  includeGate33: Bool,
  gateStatus: String = "EVIDENCE-READY-PENDING-HUMAN-REVIEW",
  launchKnownFollowUps: [String]? = nil,
  prdKnownFollowUps: [String]? = nil,
  releaseGateKnownFollowUps: [String]? = nil
) throws -> URL {
  let packageRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-release-doctor-\(UUID().uuidString)")
  let releaseRoot = packageRoot.appendingPathComponent("release/v0.0.1")
  let fixtureLaunchKnownFollowUps = launchKnownFollowUps ?? fixtureFollowUps
  let fixturePRDKnownFollowUps = prdKnownFollowUps ?? fixtureFollowUps
  let fixtureReleaseGateKnownFollowUps = releaseGateKnownFollowUps ?? fixtureFollowUps

  for path in [
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
    "release/v0.0.1/wrkstrm-app-minimums.md",
    "vaporize.engineering.docc/index.md",
    "vaporize.engineering.docc/feature-catalog.md",
    "vaporize.engineering.docc/release-doctor.md",
    "vaporize.engineering.docc/vaporware-modification-request-discipline.md",
    "vaporize.engineering.docc/modularity-and-ownership-boundaries.md",
    "vaporize.engineering.docc/feature-test-lifecycle.md",
    "vaporize.engineering.docc/swiftpm-cli-resource-bundle-installs.md",
    "vaporize.engineering.docc/product-proving-grounds.md",
  ] {
    let contents: String
    switch path {
    case "release/v0.0.1/product-definition.md":
      contents = "engineering pedigree"
    case "release/v0.0.1/prd.md":
      contents = """
      FR-027 FR-028 FR-029 FR-030 FR-031 FR-032 FR-033 FR-034 FR-035

      ## Known Release Follow-Ups

      \(markdownFollowUpList(fixturePRDKnownFollowUps))
      """
    case "release/v0.0.1/cuj.md":
      contents = "CUJ-17 CUJ-18 CUJ-19 CUJ-20 CUJ-21 CUJ-22 CUJ-23 CUJ-25 CUJ-26 CUJ-27"
    case "release/v0.0.1/release-gates.md":
      let followUpSection = """

      ## Open Follow-Up Beads

      \(markdownFollowUpList(fixtureReleaseGateKnownFollowUps))
      """
      contents = includeGate33
        ? "GATE-33-release-doctor GATE-34-project-target-discovery GATE-35-workspace-product-cache-discovery GATE-36-xcode-workspace-scheme-listing GATE-37-cuj-state-coverage GATE-38-public-disclosure-surfaces GATE-39-resource-cli-install GATE-40-product-proving-grounds Every brochure must have an audience packet and user manual owning bead cmo-chief-marketing-officer@wrkstrm.jobs.org\(followUpSection)"
        : "GATE-32 GATE-34-project-target-discovery GATE-35-workspace-product-cache-discovery GATE-36-xcode-workspace-scheme-listing GATE-37-cuj-state-coverage GATE-38-public-disclosure-surfaces GATE-39-resource-cli-install GATE-40-product-proving-grounds Every brochure must have an audience packet and user manual owning bead cmo-chief-marketing-officer@wrkstrm.jobs.org\(followUpSection)"
    case "release/v0.0.1/public-brochure.md":
      contents = "external public disclosure surface Claims Not Yet Allowed cmo-chief-marketing-officer@wrkstrm.jobs.org"
    case "release/v0.0.1/public-brochure.html":
      contents = "Build proof for assistant-run software work not approved for publication cmo-chief-marketing-officer@wrkstrm.jobs.org"
    case "release/v0.0.1/user-manual.md":
      contents = "## Brochure Companion Contract\n## Quick Start\ncmo-chief-marketing-officer@wrkstrm.jobs.org"
    case "release/v0.0.1/public-changelog.md":
      contents = "external release-note companion GATE-38-public-disclosure-surfaces cmo-chief-marketing-officer@wrkstrm.jobs.org"
    case "release/v0.0.1/evidence/audience-packet.su.json":
      contents = #"{"AudienceProfileStackModel":"0.1.0","status":"not approved for publication","ownerJobIdentitySlug":"cmo-chief-marketing-officer@wrkstrm.jobs.org"}"#
    case "vaporize.engineering.docc/feature-catalog.md":
      contents = "Release doctor Project target discovery Workspace product-cache discovery Xcode workspace scheme listing SwiftPM CLI resource-bundle installs Vaporware product proving grounds"
    case "vaporize.engineering.docc/vaporware-modification-request-discipline.md":
      contents = "vaporware scaffold feature-request owning bead"
    case "vaporize.engineering.docc/swiftpm-cli-resource-bundle-installs.md":
      contents = "Bundle.module"
    case "vaporize.engineering.docc/product-proving-grounds.md":
      contents = "proving-ground passport"
    default:
      contents = "fixture"
    }
    try write(contents, to: packageRoot.appendingPathComponent(path))
  }

  let gateResults = includeGate33
    ? "{\"gateRef\":\"GATE-33-release-doctor\",\"status\":\"\(gateStatus)\",\"rationale\":\"fixture\"}"
    : "{\"gateRef\":\"GATE-32\",\"status\":\"\(gateStatus)\",\"rationale\":\"fixture\"}"
  try write(
    """
    {
      "subjectAppSlug": "vaporize.cli@wrkstrm-core.clia.sh",
      "evidenceRefs": [
        { "t": "Release doctor receipt" },
        { "t": "Creative Selection v0.2 target discovery receipt" },
        { "t": "Creative Selection v0.2 workspace cache discovery receipt" },
        { "t": "Vaporize v0.0.1 public brochure" },
        { "t": "Vaporize v0.0.1 public brochure marketing site" },
        { "t": "Vaporize v0.0.1 public brochure audience packet" },
        { "t": "Vaporize v0.0.1 user manual" },
        { "t": "Vaporize v0.0.1 public changelog" },
        { "t": "Vaporize CUJ-22 resource CLI install test bundle" },
        { "t": "Vaporize CUJ-23 product proving-ground adoption test bundle" }
      ],
      "knownFollowUps": \(jsonStringArray(fixtureLaunchKnownFollowUps)),
      "gateResults": [
        \(gateResults),
        { "gateRef": "GATE-34-project-target-discovery", "status": "\(gateStatus)", "rationale": "fixture" },
        { "gateRef": "GATE-35-workspace-product-cache-discovery", "status": "\(gateStatus)", "rationale": "fixture" },
        { "gateRef": "GATE-36-xcode-workspace-scheme-listing", "status": "\(gateStatus)", "rationale": "fixture" },
        { "gateRef": "GATE-37-cuj-state-coverage", "status": "\(gateStatus)", "rationale": "fixture" },
        { "gateRef": "GATE-38-public-disclosure-surfaces", "status": "\(gateStatus)", "rationale": "fixture" },
        { "gateRef": "GATE-39-resource-cli-install", "status": "\(gateStatus)", "rationale": "fixture" },
        { "gateRef": "GATE-40-product-proving-grounds", "status": "\(gateStatus)", "rationale": "fixture" },
        { "gateRef": "GATE-14-pkl-project-generation", "status": "BLOCKED", "rationale": "fixture hard blocker" }
      ],
      "humanReviewPolicy": {
        "approvalStatusRequiresHumanReview": true,
        "automationSignerAllowed": false,
        "machineProofMayApproveGate": false
      },
      "consumerFacingGateOwnership": {
        "ownerStatus": "assigned-not-signed-off",
        "ownerName": "Carrie CMO",
        "ownerJobIdentitySlug": "cmo-chief-marketing-officer@wrkstrm.jobs.org"
      },
      "signoffs": {
        "audienceApproverSignoffRef": null,
        "founderSignoffRef": null
      }
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/launch-review-packet.json")
  )

  try write(
    """
    {
      "humanApprovalBoundary": {
        "automationCanApproveGate": false,
        "approvedStatusesRequireHumanReview": true,
        "requiredPendingStatus": "EVIDENCE-READY-PENDING-HUMAN-REVIEW"
      },
      "launchReviewGateStatusRecommendation": {
        "evidenceReadyPendingHumanReview": 8,
        "blocked": 1
      },
      "remainingHardBlockers": [
        { "gateRef": "GATE-14-pkl-project-generation" }
      ],
      "burnedDownDuplicateOrScopedBlockers": [
        { "gateRef": "GATE-12-open-feature-beads" },
        { "gateRef": "GATE-13-tree-cleanliness" },
        { "gateRef": "GATE-27-runtime-sample-series-apple-artifact-ingestion" }
      ],
      "followUpDispositions": \(jsonFollowUpDispositionArray(fixtureLaunchKnownFollowUps))
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/launch-review-blocker-disposition.json")
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
        "activeCUJCount": 27,
        "requiredReleaseEvidenceCheckCount": 14,
        "currentExecutableSwiftTestBreakdown": {
          "VaporizeCUJ10YMLPklComparisonTests": 5,
          "VaporizeCUJ13YMLPklImportTests": 5,
          "VaporizeCUJ17ReleaseDoctorTests": 7,
          "VaporizeCUJ14PklXcodeProjectGenerationTests": 7,
          "VaporizeCUJ18ListTargetsTests": 5,
          "VaporizeCUJ19WorkspaceCacheDiscoveryTests": 5,
          "VaporizeCUJ20XcodeWorkspaceSchemesTests": 5,
          "VaporizeCUJ21CUJStateTests": 6,
          "VaporizeCUJ22ResourceCLIInstallTests": 6,
          "VaporizeCUJ23ProductProvingGroundTests": 4,
          "VaporizeCUJ25PortfolioAuditTests": 4,
          "VaporizeCUJ26AutomatedProofLedgerTests": 5,
          "VaporizeCUJ27ProjectCoverageLedgerTests": 4
        }
      }
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/cuj-test-coverage.json")
  )

  try write(
    """
    {
      "schemaVersion": "0.1.0",
      "documentKind": "cuj-state-coverage",
      "stateFamily": "cuj-state",
      "stateSlug": "scm-product-suite",
      "statePath": "release/v0.0.1/evidence/cuj-state.json",
      "requiredStateIDs": [
        "scm-product-suite.cuj.savepoint-emits-boundary-aware-commit"
      ],
      "proofs": [
        {
          "stateID": "scm-product-suite.cuj.savepoint-emits-boundary-aware-commit",
          "proofKind": "behavior-proof",
          "testTarget": "VaporizeCUJ21CUJStateTests",
          "testName": "cujStateCoverageGateRequiresEveryStateID",
          "receiptRef": "command-receipt://vaporize/cuj21-cuj-state/coverage-gate"
        }
      ],
      "coveredStateIDs": [
        "scm-product-suite.cuj.savepoint-emits-boundary-aware-commit"
      ],
      "uncoveredStateIDs": [],
      "unknownStateIDs": [],
      "duplicateProofStateIDs": [],
      "coverageStatus": "pass",
      "createdAt": "1970-01-01T00:00:00Z"
    }
    """,
    to: releaseRoot.appendingPathComponent("evidence/cuj-state-coverage.json")
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

private func markdownFollowUpList(_ refs: [String]) -> String {
  refs.map { "- `\($0)`" }.joined(separator: "\n")
}

private func jsonStringArray(_ values: [String]) -> String {
  let data = try! JSONSerialization.data(withJSONObject: values)
  return String(data: data, encoding: .utf8)!
}

private func jsonFollowUpDispositionArray(_ refs: [String]) -> String {
  let values = refs.map { ["followUpRef": $0] }
  let data = try! JSONSerialization.data(withJSONObject: values)
  return String(data: data, encoding: .utf8)!
}
