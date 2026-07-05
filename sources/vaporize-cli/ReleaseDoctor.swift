import Foundation
import SwiftJSONFormatter

enum VaporizeReleaseDoctor {
  static let schemaVersion = "0.1.0"
  static let schemaFamilySlug = "vaporize-schemas"
  static let schemaFamilyVersion = "0.0.1"
  static let schemaRef =
    "private/universal/domain/tooling/schema-families/vaporize-schemas/v0.0.1/json/vaporize-schemas-v000-000-001/schemas/vaporize-release-doctor-receipt/vaporize-release-doctor-receipt.schema.json"

  static func inspect(path: String, requestId: String) throws -> VaporizeReleaseDoctorReceipt {
    let roots = try resolveRoots(path: path)
    var checks: [VaporizeReleaseDoctorCheck] = []

    for artifact in requiredArtifacts {
      let url = roots.url(for: artifact.scope, relativePath: artifact.relativePath)
      checks.append(
        check(
          name: "artifact:\(artifact.relativePath)",
          category: "required-artifact",
          path: url.path,
          passed: FileManager.default.fileExists(atPath: url.path),
          detail: "Required \(artifact.scope.rawValue) artifact exists."
        )
      )
    }

    for artifact in jsonArtifacts {
      let url = roots.url(for: artifact.scope, relativePath: artifact.relativePath)
      checks.append(jsonCheck(name: "json:\(artifact.relativePath)", url: url))
    }

    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "product-definition.md",
        token: "engineering pedigree",
        name: "product-definition-engineering-pedigree"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "prd.md",
        token: "FR-027",
        name: "prd-release-doctor-requirement"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "prd.md",
        token: "FR-028",
        name: "prd-project-target-discovery-requirement"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "prd.md",
        token: "FR-029",
        name: "prd-workspace-cache-discovery-requirement"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "prd.md",
        token: "FR-030",
        name: "prd-xcode-workspace-scheme-listing-requirement"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "prd.md",
        token: "FR-031",
        name: "prd-cuj-state-coverage-requirement"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "prd.md",
        token: "FR-032",
        name: "prd-resource-cli-install-requirement"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "cuj.md",
        token: "CUJ-17",
        name: "cuj-release-doctor-journey"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "cuj.md",
        token: "CUJ-18",
        name: "cuj-project-target-discovery-journey"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "cuj.md",
        token: "CUJ-19",
        name: "cuj-workspace-cache-discovery-journey"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "cuj.md",
        token: "CUJ-20",
        name: "cuj-xcode-workspace-scheme-listing-journey"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "cuj.md",
        token: "CUJ-21",
        name: "cuj-cuj-state-coverage-journey"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "cuj.md",
        token: "CUJ-22",
        name: "cuj-resource-cli-install-journey"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "GATE-33-release-doctor",
        name: "gate-release-doctor"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "GATE-34-project-target-discovery",
        name: "gate-project-target-discovery"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "GATE-35-workspace-product-cache-discovery",
        name: "gate-workspace-cache-discovery"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "GATE-36-xcode-workspace-scheme-listing",
        name: "gate-xcode-workspace-scheme-listing"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "GATE-37-cuj-state-coverage",
        name: "gate-cuj-state-coverage"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "GATE-38-public-disclosure-surfaces",
        name: "gate-public-disclosure-surfaces"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "GATE-39-resource-cli-install",
        name: "gate-resource-cli-install"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "Every brochure must have an audience packet and user manual",
        name: "gate-brochure-companion-contract"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "owning bead",
        name: "gate-vaporware-owning-bead-discipline"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "release-gates.md",
        token: "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org",
        name: "gate-public-disclosure-carrie-cmo-owner"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-brochure.md",
        token: "external public disclosure surface",
        name: "public-brochure-disclosure-boundary"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-brochure.md",
        token: "Claims Not Yet Allowed",
        name: "public-brochure-claim-boundary"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-brochure.md",
        token: "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org",
        name: "public-brochure-carrie-cmo-owner"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-brochure.html",
        token: "Build proof for assistant-run software work",
        name: "public-brochure-html-marketing-site-headline"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-brochure.html",
        token: "not approved for publication",
        name: "public-brochure-html-disclosure-boundary"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-brochure.html",
        token: "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org",
        name: "public-brochure-html-carrie-cmo-owner"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "evidence/audience-packet.su.json",
        token: "AudienceProfileStackModel",
        name: "audience-packet-model"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "evidence/audience-packet.su.json",
        token: "not approved for publication",
        name: "audience-packet-publication-boundary"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "evidence/audience-packet.su.json",
        token: "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org",
        name: "audience-packet-carrie-cmo-owner"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "user-manual.md",
        token: "Brochure Companion Contract",
        name: "user-manual-brochure-companion-contract"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "user-manual.md",
        token: "## Quick Start",
        name: "user-manual-quick-start"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "user-manual.md",
        token: "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org",
        name: "user-manual-carrie-cmo-owner"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-changelog.md",
        token: "external release-note companion",
        name: "public-changelog-disclosure-boundary"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-changelog.md",
        token: "GATE-38-public-disclosure-surfaces",
        name: "public-changelog-gate-reference"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .releaseRoot,
        relativePath: "public-changelog.md",
        token: "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org",
        name: "public-changelog-carrie-cmo-owner"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/feature-catalog.md",
        token: "Release doctor",
        name: "feature-catalog-release-doctor"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/feature-catalog.md",
        token: "Project target discovery",
        name: "feature-catalog-project-target-discovery"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/feature-catalog.md",
        token: "Workspace product-cache discovery",
        name: "feature-catalog-workspace-cache-discovery"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/feature-catalog.md",
        token: "Xcode workspace scheme listing",
        name: "feature-catalog-xcode-workspace-scheme-listing"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/feature-catalog.md",
        token: "SwiftPM CLI resource-bundle installs",
        name: "feature-catalog-resource-cli-install"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/swiftpm-cli-resource-bundle-installs.md",
        token: "Bundle.module",
        name: "swiftpm-cli-resource-bundle-doc"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/vaporware-modification-request-discipline.md",
        token: "vaporware scaffold",
        name: "vaporware-scaffold-vocabulary"
      )
    )
    checks.append(
      textContainsCheck(
        roots: roots,
        scope: .packageRoot,
        relativePath: "vaporize.engineering.docc/vaporware-modification-request-discipline.md",
        token: "owning bead",
        name: "vaporware-modification-owning-bead-discipline"
      )
    )

    checks.append(contentsOf: launchReviewChecks(roots: roots))
    checks.append(contentsOf: provenanceChecks(roots: roots))
    checks.append(contentsOf: coverageChecks(roots: roots))
    checks.append(contentsOf: cujStateCoverageChecks(roots: roots))

    let failedCheckCount = checks.filter { $0.status == "fail" }.count
    let warningCheckCount = checks.filter { $0.status == "warn" }.count
    let passedCheckCount = checks.filter { $0.status == "pass" }.count
    return VaporizeReleaseDoctorReceipt(
      schemaRef: schemaRef,
      requestId: requestId,
      subjectAppSlug: "vaporize.cli@wrkstrm-core.clia.sh",
      subjectReleaseSlug: "v0.0.1",
      inspectedPath: URL(fileURLWithPath: path).standardizedFileURL.path,
      packageRootPath: roots.packageRoot.path,
      releaseRootPath: roots.releaseRoot.path,
      overallStatus: failedCheckCount == 0 ? "pass" : "fail",
      requiredArtifactCount: requiredArtifacts.count,
      checkCount: checks.count,
      passedCheckCount: passedCheckCount,
      failedCheckCount: failedCheckCount,
      warningCheckCount: warningCheckCount,
      checks: checks
    )
  }

  private static let requiredArtifacts: [ReleaseDoctorArtifact] = [
    .release("product-definition.md"),
    .release("prd.md"),
    .release("prd-review-session.md"),
    .release("cuj.md"),
    .release("release-gates.md"),
    .release("why-vaporize.md"),
    .release("performance-marketing-claims.md"),
    .release("public-brochure.md"),
    .release("public-brochure.html"),
    .release("user-manual.md"),
    .release("public-changelog.md"),
    .release("wrkstrm-app-minimums.md"),
    .release("evidence/cuj-test-coverage.json"),
    .release("evidence/cuj-state-coverage.json"),
    .release("evidence/audience-packet.su.json"),
    .release("evidence/launch-review-packet.json"),
    .release("evidence/vaporize-v0.0.1-provenance-artifact.json"),
    .release("evidence/creative-selection-v0.2-list-targets.receipt.json"),
    .release("evidence/creative-selection-v0.2-workspace-cache-discovery.receipt.json"),
    .package("vaporize.engineering.docc/index.md"),
    .package("vaporize.engineering.docc/feature-catalog.md"),
    .package("vaporize.engineering.docc/release-doctor.md"),
    .package("vaporize.engineering.docc/vaporware-modification-request-discipline.md"),
    .package("vaporize.engineering.docc/modularity-and-ownership-boundaries.md"),
    .package("vaporize.engineering.docc/feature-test-lifecycle.md"),
    .package("vaporize.engineering.docc/swiftpm-cli-resource-bundle-installs.md"),
  ]

  private static let jsonArtifacts: [ReleaseDoctorArtifact] = [
    .release("evidence/cuj-test-coverage.json"),
    .release("evidence/cuj-state-coverage.json"),
    .release("evidence/audience-packet.su.json"),
    .release("evidence/launch-review-packet.json"),
    .release("evidence/vaporize-v0.0.1-provenance-artifact.json"),
    .release("evidence/creative-selection-v0.2-list-targets.receipt.json"),
    .release("evidence/creative-selection-v0.2-workspace-cache-discovery.receipt.json"),
  ]

  private static func resolveRoots(path: String) throws -> ReleaseDoctorRoots {
    let input = URL(fileURLWithPath: path).standardizedFileURL
    let fm = FileManager.default

    if fm.fileExists(atPath: input.appendingPathComponent("release/v0.0.1/prd.md").path) {
      return ReleaseDoctorRoots(
        packageRoot: input,
        releaseRoot: input.appendingPathComponent("release/v0.0.1")
      )
    }

    if input.lastPathComponent == "v0.0.1",
      input.deletingLastPathComponent().lastPathComponent == "release",
      fm.fileExists(atPath: input.appendingPathComponent("prd.md").path)
    {
      return ReleaseDoctorRoots(
        packageRoot: input.deletingLastPathComponent().deletingLastPathComponent(),
        releaseRoot: input
      )
    }

    if input.lastPathComponent == "release",
      fm.fileExists(atPath: input.appendingPathComponent("v0.0.1/prd.md").path)
    {
      return ReleaseDoctorRoots(
        packageRoot: input.deletingLastPathComponent(),
        releaseRoot: input.appendingPathComponent("v0.0.1")
      )
    }

    throw ReleaseDoctorError.unresolvedRoot(path)
  }

  private static func jsonCheck(name: String, url: URL) -> VaporizeReleaseDoctorCheck {
    do {
      let data = try Data(contentsOf: url)
      _ = try SwiftJSONFormatter.parseJSONObject(from: data)
      return check(
        name: name,
        category: "json-validation",
        path: url.path,
        passed: true,
        detail: "JSON parses through Swift Universal JSON formatting."
      )
    } catch {
      return check(
        name: name,
        category: "json-validation",
        path: url.path,
        passed: false,
        detail: "JSON failed to parse: \(error)"
      )
    }
  }

  private static func textContainsCheck(
    roots: ReleaseDoctorRoots,
    scope: ReleaseDoctorScope,
    relativePath: String,
    token: String,
    name: String
  ) -> VaporizeReleaseDoctorCheck {
    let url = roots.url(for: scope, relativePath: relativePath)
    do {
      let text = try String(contentsOf: url, encoding: .utf8)
      return check(
        name: name,
        category: "release-spine-text",
        path: url.path,
        passed: text.contains(token),
        detail: "Expected token `\(token)` in \(relativePath)."
      )
    } catch {
      return check(
        name: name,
        category: "release-spine-text",
        path: url.path,
        passed: false,
        detail: "Could not read \(relativePath): \(error)"
      )
    }
  }

  private static func launchReviewChecks(roots: ReleaseDoctorRoots) -> [VaporizeReleaseDoctorCheck] {
    let relativePath = "evidence/launch-review-packet.json"
    let url = roots.url(for: .releaseRoot, relativePath: relativePath)
    guard let object = jsonObject(url: url) else {
      return [
        check(
          name: "launch-review-packet-readable",
          category: "launch-review",
          path: url.path,
          passed: false,
          detail: "Could not decode launch-review packet as a JSON object."
        )
      ]
    }

    let gateResults = object["gateResults"] as? [[String: Any]] ?? []
    let evidenceRefs = object["evidenceRefs"] as? [[String: Any]] ?? []
    let consumerFacingGateOwnership = object["consumerFacingGateOwnership"] as? [String: Any] ?? [:]
    let signoffs = object["signoffs"] as? [String: Any] ?? [:]
    return [
      check(
        name: "launch-review-subject",
        category: "launch-review",
        path: url.path,
        passed: object["subjectAppSlug"] as? String == "vaporize.cli@wrkstrm-core.clia.sh",
        detail: "Launch-review packet subjectAppSlug must name Vaporize."
      ),
      check(
        name: "launch-review-gate-33",
        category: "launch-review",
        path: url.path,
        passed: gateResults.contains { $0["gateRef"] as? String == "GATE-33-release-doctor" },
        detail: "Launch-review packet must include the release-doctor gate."
      ),
      check(
        name: "launch-review-gate-34",
        category: "launch-review",
        path: url.path,
        passed: gateResults.contains { $0["gateRef"] as? String == "GATE-34-project-target-discovery" },
        detail: "Launch-review packet must include the project target discovery gate."
      ),
      check(
        name: "launch-review-gate-35",
        category: "launch-review",
        path: url.path,
        passed: gateResults.contains { $0["gateRef"] as? String == "GATE-35-workspace-product-cache-discovery" },
        detail: "Launch-review packet must include the workspace product-cache discovery gate."
      ),
      check(
        name: "launch-review-gate-36",
        category: "launch-review",
        path: url.path,
        passed: gateResults.contains { $0["gateRef"] as? String == "GATE-36-xcode-workspace-scheme-listing" },
        detail: "Launch-review packet must include the Xcode workspace scheme-listing gate."
      ),
      check(
        name: "launch-review-gate-37",
        category: "launch-review",
        path: url.path,
        passed: gateResults.contains { $0["gateRef"] as? String == "GATE-37-cuj-state-coverage" },
        detail: "Launch-review packet must include the CUJ-state coverage gate."
      ),
      check(
        name: "launch-review-gate-38",
        category: "launch-review",
        path: url.path,
        passed: gateResults.contains { $0["gateRef"] as? String == "GATE-38-public-disclosure-surfaces" },
        detail: "Launch-review packet must include the public-disclosure surfaces gate."
      ),
      check(
        name: "launch-review-gate-39",
        category: "launch-review",
        path: url.path,
        passed: gateResults.contains { $0["gateRef"] as? String == "GATE-39-resource-cli-install" },
        detail: "Launch-review packet must include the SwiftPM CLI resource-bundle install gate."
      ),
      check(
        name: "launch-review-carrie-cmo-owner",
        category: "launch-review",
        path: url.path,
        passed: consumerFacingGateOwnership["ownerOccupationSlug"] as? String
          == "cmo-chief-marketing-officer-carrie@wrkstrm.occupations.org",
        detail: "Launch-review packet must assign the consumer-facing public-disclosure gate to Carrie CMO."
      ),
      check(
        name: "launch-review-carrie-cmo-not-signed-off",
        category: "launch-review",
        path: url.path,
        passed: consumerFacingGateOwnership["ownerStatus"] as? String == "assigned-not-signed-off"
          && isNullish(signoffs["audienceApproverSignoffRef"])
          && isNullish(signoffs["founderSignoffRef"]),
        detail: "Carrie CMO ownership must remain distinct from publication approval signoff."
      ),
      check(
        name: "launch-review-release-doctor-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Release doctor receipt" },
        detail: "Launch-review packet must reference the release-doctor receipt."
      ),
      check(
        name: "launch-review-project-target-discovery-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Creative Selection v0.2 target discovery receipt" },
        detail: "Launch-review packet must reference the project target discovery receipt."
      ),
      check(
        name: "launch-review-workspace-cache-discovery-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Creative Selection v0.2 workspace cache discovery receipt" },
        detail: "Launch-review packet must reference the workspace product-cache discovery receipt."
      ),
      check(
        name: "launch-review-public-brochure-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 public brochure" },
        detail: "Launch-review packet must reference the public brochure."
      ),
      check(
        name: "launch-review-public-brochure-html-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 public brochure marketing site" },
        detail: "Launch-review packet must reference the public brochure marketing site."
      ),
      check(
        name: "launch-review-audience-packet-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 public brochure audience packet" },
        detail: "Launch-review packet must reference the public brochure audience packet."
      ),
      check(
        name: "launch-review-user-manual-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 user manual" },
        detail: "Launch-review packet must reference the user manual."
      ),
      check(
        name: "launch-review-public-changelog-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Vaporize v0.0.1 public changelog" },
        detail: "Launch-review packet must reference the public changelog."
      ),
      check(
        name: "launch-review-resource-cli-install-evidence-ref",
        category: "launch-review",
        path: url.path,
        passed: evidenceRefs.contains { $0["t"] as? String == "Vaporize CUJ-22 resource CLI install test bundle" },
        detail: "Launch-review packet must reference the resource-bearing CLI install test bundle."
      ),
    ]
  }

  private static func provenanceChecks(roots: ReleaseDoctorRoots) -> [VaporizeReleaseDoctorCheck] {
    let relativePath = "evidence/vaporize-v0.0.1-provenance-artifact.json"
    let url = roots.url(for: .releaseRoot, relativePath: relativePath)
    guard let object = jsonObject(url: url) else {
      return [
        check(
          name: "provenance-readable",
          category: "provenance",
          path: url.path,
          passed: false,
          detail: "Could not decode provenance artifact as a JSON object."
        )
      ]
    }

    let receiptInventory = object["receiptInventory"] as? [[String: Any]] ?? []
    return [
      check(
        name: "provenance-release-doctor-receipt",
        category: "provenance",
        path: url.path,
        passed: receiptInventory.contains { $0["receiptKind"] as? String == "vaporize-release-doctor" },
        detail: "Provenance must inventory the release-doctor receipt."
      ),
      check(
        name: "provenance-project-target-discovery-receipt",
        category: "provenance",
        path: url.path,
        passed: receiptInventory.contains { $0["receiptKind"] as? String == "vaporize-project-target-discovery" },
        detail: "Provenance must inventory the project target discovery receipt."
      ),
      check(
        name: "provenance-workspace-cache-discovery-receipt",
        category: "provenance",
        path: url.path,
        passed: receiptInventory.contains {
          $0["receiptKind"] as? String == "vaporize-project-target-discovery"
            && (($0["claim"] as? String)?.contains("workspace product-cache") ?? false)
        },
        detail: "Provenance must inventory the workspace product-cache discovery receipt."
      )
    ]
  }

  private static func coverageChecks(roots: ReleaseDoctorRoots) -> [VaporizeReleaseDoctorCheck] {
    let relativePath = "evidence/cuj-test-coverage.json"
    let url = roots.url(for: .releaseRoot, relativePath: relativePath)
    guard
      let object = jsonObject(url: url),
      let counts = object["counts"] as? [String: Any],
      let breakdown = counts["currentExecutableSwiftTestBreakdown"] as? [String: Any]
    else {
      return [
        check(
          name: "coverage-readable",
          category: "cuj-coverage",
          path: url.path,
          passed: false,
          detail: "Could not decode CUJ coverage counts."
        )
      ]
    }

    return [
      check(
        name: "coverage-active-cuj-22",
        category: "cuj-coverage",
        path: url.path,
        passed: (counts["activeCUJCount"] as? Int ?? 0) >= 22,
        detail: "Coverage artifact must count CUJ-22 resource-bearing CLI install coverage."
      ),
      check(
        name: "coverage-release-evidence-floor",
        category: "cuj-coverage",
        path: url.path,
        passed: (counts["requiredReleaseEvidenceCheckCount"] as? Int ?? 0) >= 12,
        detail: "Coverage artifact must include release-doctor, target discovery, workspace cache discovery, and CUJ-state coverage evidence obligations."
      ),
      check(
        name: "coverage-release-doctor-test-bundle",
        category: "cuj-coverage",
        path: url.path,
        passed: (breakdown["VaporizeCUJ17ReleaseDoctorTests"] as? Int ?? 0) >= 4,
        detail: "Coverage artifact must name the CUJ-17 targetable test bundle."
      ),
      check(
        name: "coverage-project-target-discovery-test-bundle",
        category: "cuj-coverage",
        path: url.path,
        passed: (breakdown["VaporizeCUJ18ListTargetsTests"] as? Int ?? 0) >= 5,
        detail: "Coverage artifact must name the CUJ-18 targetable test bundle."
      ),
      check(
        name: "coverage-workspace-cache-discovery-test-bundle",
        category: "cuj-coverage",
        path: url.path,
        passed: (breakdown["VaporizeCUJ19WorkspaceCacheDiscoveryTests"] as? Int ?? 0) >= 5,
        detail: "Coverage artifact must name the CUJ-19 targetable test bundle."
      ),
      check(
        name: "coverage-xcode-workspace-scheme-listing-test-bundle",
        category: "cuj-coverage",
        path: url.path,
        passed: (breakdown["VaporizeCUJ20XcodeWorkspaceSchemesTests"] as? Int ?? 0) >= 5,
        detail: "Coverage artifact must name the CUJ-20 targetable test bundle."
      ),
      check(
        name: "coverage-cuj-state-test-bundle",
        category: "cuj-coverage",
        path: url.path,
        passed: (breakdown["VaporizeCUJ21CUJStateTests"] as? Int ?? 0) >= 6,
        detail: "Coverage artifact must name the CUJ-21 targetable test bundle."
      ),
      check(
        name: "coverage-resource-cli-install-test-bundle",
        category: "cuj-coverage",
        path: url.path,
        passed: (breakdown["VaporizeCUJ22ResourceCLIInstallTests"] as? Int ?? 0) >= 6,
        detail: "Coverage artifact must name the CUJ-22 targetable test bundle."
      ),
    ]
  }

  private static func cujStateCoverageChecks(roots: ReleaseDoctorRoots) -> [VaporizeReleaseDoctorCheck] {
    let relativePath = "evidence/cuj-state-coverage.json"
    let url = roots.url(for: .releaseRoot, relativePath: relativePath)
    guard let object = jsonObject(url: url) else {
      return [
        check(
          name: "cuj-state-coverage-readable",
          category: "cuj-state-coverage",
          path: url.path,
          passed: false,
          detail: "Could not decode CUJ-state coverage as a JSON object."
        )
      ]
    }

    let requiredStateIDs = object["requiredStateIDs"] as? [String] ?? []
    let uncoveredStateIDs = object["uncoveredStateIDs"] as? [String] ?? []
    let unknownStateIDs = object["unknownStateIDs"] as? [String] ?? []
    let duplicateProofStateIDs = object["duplicateProofStateIDs"] as? [String] ?? []
    let proofs = object["proofs"] as? [[String: Any]] ?? []
    let proofStateIDs = Set(proofs.compactMap { $0["stateID"] as? String })

    return [
      check(
        name: "cuj-state-coverage-document-kind",
        category: "cuj-state-coverage",
        path: url.path,
        passed: object["documentKind"] as? String == "cuj-state-coverage",
        detail: "CUJ-state coverage evidence must be a cuj-state-coverage document."
      ),
      check(
        name: "cuj-state-coverage-state-family",
        category: "cuj-state-coverage",
        path: url.path,
        passed: object["stateFamily"] as? String == "cuj-state",
        detail: "CUJ-state coverage evidence must name stateFamily cuj-state."
      ),
      check(
        name: "cuj-state-coverage-status",
        category: "cuj-state-coverage",
        path: url.path,
        passed: object["coverageStatus"] as? String == "pass",
        detail: "CUJ-state coverage evidence must report coverageStatus pass."
      ),
      check(
        name: "cuj-state-required-records",
        category: "cuj-state-coverage",
        path: url.path,
        passed: !requiredStateIDs.isEmpty,
        detail: "CUJ-state coverage evidence must name every required CUJ-state id."
      ),
      check(
        name: "cuj-state-proof-floor",
        category: "cuj-state-coverage",
        path: url.path,
        passed: proofs.count >= requiredStateIDs.count && requiredStateIDs.allSatisfy { proofStateIDs.contains($0) },
        detail: "Each required CUJ-state id must have at least one proof entry."
      ),
      check(
        name: "cuj-state-uncovered-empty",
        category: "cuj-state-coverage",
        path: url.path,
        passed: uncoveredStateIDs.isEmpty,
        detail: "CUJ-state coverage evidence must not list uncovered state ids."
      ),
      check(
        name: "cuj-state-unknown-empty",
        category: "cuj-state-coverage",
        path: url.path,
        passed: unknownStateIDs.isEmpty,
        detail: "CUJ-state coverage evidence must not claim unknown state ids."
      ),
      check(
        name: "cuj-state-duplicate-proof-empty",
        category: "cuj-state-coverage",
        path: url.path,
        passed: duplicateProofStateIDs.isEmpty,
        detail: "CUJ-state coverage evidence must not duplicate proof state ids."
      ),
    ]
  }

  private static func jsonObject(url: URL) -> [String: Any]? {
    guard let data = try? Data(contentsOf: url),
      let object = try? SwiftJSONFormatter.parseJSONObject(from: data)
    else {
      return nil
    }
    return object as? [String: Any]
  }

  private static func isNullish(_ value: Any?) -> Bool {
    value == nil || value is NSNull
  }

  private static func check(
    name: String,
    category: String,
    path: String?,
    passed: Bool,
    detail: String
  ) -> VaporizeReleaseDoctorCheck {
    VaporizeReleaseDoctorCheck(
      name: name,
      category: category,
      status: passed ? "pass" : "fail",
      severity: "blocking",
      path: path,
      detail: detail
    )
  }
}

struct VaporizeReleaseDoctorReceipt: Codable, Equatable {
  var schemaVersion = VaporizeReleaseDoctor.schemaVersion
  var schemaFamilySlug = VaporizeReleaseDoctor.schemaFamilySlug
  var schemaFamilyVersion = VaporizeReleaseDoctor.schemaFamilyVersion
  var schemaRef: String
  var receiptKind = "vaporize-release-doctor"
  var doctorPhase = "release-spine-first-slice"
  var requestId: String
  var subjectAppSlug: String
  var subjectReleaseSlug: String
  var inspectedPath: String
  var packageRootPath: String
  var releaseRootPath: String
  var overallStatus: String
  var requiredArtifactCount: Int
  var checkCount: Int
  var passedCheckCount: Int
  var failedCheckCount: Int
  var warningCheckCount: Int
  var checks: [VaporizeReleaseDoctorCheck]
  var boundaries = [
    "Release doctor audits release-spine coherence; it does not approve release.",
    "A pass can coexist with release gates that are honestly blocked.",
    "First slice checks Vaporize v0.0.1 docs, public-disclosure surfaces, JSON evidence, CUJ coverage, CUJ-state coverage, launch-review references, provenance inventory, project target discovery evidence, workspace product-cache discovery evidence, and Xcode workspace scheme-listing evidence.",
    "Fleet project-generation parity, runtime sampling, build-size cohorts, and periodic buddy health remain separate follow-up checks.",
  ]
}

struct VaporizeReleaseDoctorCheck: Codable, Equatable {
  var name: String
  var category: String
  var status: String
  var severity: String
  var path: String?
  var detail: String
}

private struct ReleaseDoctorArtifact {
  var scope: ReleaseDoctorScope
  var relativePath: String

  static func package(_ relativePath: String) -> ReleaseDoctorArtifact {
    ReleaseDoctorArtifact(scope: .packageRoot, relativePath: relativePath)
  }

  static func release(_ relativePath: String) -> ReleaseDoctorArtifact {
    ReleaseDoctorArtifact(scope: .releaseRoot, relativePath: relativePath)
  }
}

private struct ReleaseDoctorRoots {
  var packageRoot: URL
  var releaseRoot: URL

  func url(for scope: ReleaseDoctorScope, relativePath: String) -> URL {
    switch scope {
    case .packageRoot:
      return packageRoot.appendingPathComponent(relativePath).standardizedFileURL
    case .releaseRoot:
      return releaseRoot.appendingPathComponent(relativePath).standardizedFileURL
    }
  }
}

private enum ReleaseDoctorScope: String {
  case packageRoot = "package-root"
  case releaseRoot = "release-root"
}

enum ReleaseDoctorError: Error, CustomStringConvertible {
  case unresolvedRoot(String)

  var description: String {
    switch self {
    case .unresolvedRoot(let path):
      return "release-doctor could not resolve a Vaporize package root or release/v0.0.1 root from \(path)."
    }
  }
}
