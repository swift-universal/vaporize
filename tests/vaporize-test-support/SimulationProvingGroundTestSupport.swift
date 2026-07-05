import Foundation

public struct VaporizeSimulationProvingGroundManifest: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var kind: String
  public var slug: String
  public var title: String
  public var owningToolRef: String
  public var scenarios: [VaporizeSimulationProvingGroundScenario]
  public var metadata: [String: String]

  public init(
    schemaVersion: String = "0.1.0",
    kind: String = "simulation-proving-ground-test",
    slug: String,
    title: String,
    owningToolRef: String,
    scenarios: [VaporizeSimulationProvingGroundScenario],
    metadata: [String: String] = [:]
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.slug = slug
    self.title = title
    self.owningToolRef = owningToolRef
    self.scenarios = scenarios
    self.metadata = metadata
  }
}

public struct VaporizeSimulationProvingGroundScenario: Codable, Equatable, Sendable {
  public var slug: String
  public var title: String
  public var fixtureKind: String
  public var resourceMode: String
  public var expectedStdout: String
  public var isolationRequirements: [String]
  public var cleanupRequirements: [String]
  public var proofCommandRefs: [String]

  public init(
    slug: String,
    title: String,
    fixtureKind: String,
    resourceMode: String,
    expectedStdout: String,
    isolationRequirements: [String],
    cleanupRequirements: [String],
    proofCommandRefs: [String]
  ) {
    self.slug = slug
    self.title = title
    self.fixtureKind = fixtureKind
    self.resourceMode = resourceMode
    self.expectedStdout = expectedStdout
    self.isolationRequirements = isolationRequirements
    self.cleanupRequirements = cleanupRequirements
    self.proofCommandRefs = proofCommandRefs
  }
}

public struct VaporizeSimulationProvingGroundReceipt: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var kind: String
  public var provingGroundSlug: String
  public var scenarioSlug: String
  public var fixtureKind: String
  public var resourceMode: String
  public var product: String
  public var installedExecutablePath: String
  public var installedResourceBundleNames: [String]
  public var buildProductsHiddenDuringExecution: Bool
  public var exitCode: Int32
  public var stdout: String
  public var stderr: String
  public var status: String

  public init(
    schemaVersion: String = "0.1.0",
    kind: String = "simulation-proving-ground-receipt",
    provingGroundSlug: String,
    scenarioSlug: String,
    fixtureKind: String,
    resourceMode: String,
    product: String,
    installedExecutablePath: String,
    installedResourceBundleNames: [String],
    buildProductsHiddenDuringExecution: Bool,
    exitCode: Int32,
    stdout: String,
    stderr: String,
    status: String
  ) {
    self.schemaVersion = schemaVersion
    self.kind = kind
    self.provingGroundSlug = provingGroundSlug
    self.scenarioSlug = scenarioSlug
    self.fixtureKind = fixtureKind
    self.resourceMode = resourceMode
    self.product = product
    self.installedExecutablePath = installedExecutablePath
    self.installedResourceBundleNames = installedResourceBundleNames
    self.buildProductsHiddenDuringExecution = buildProductsHiddenDuringExecution
    self.exitCode = exitCode
    self.stdout = stdout
    self.stderr = stderr
    self.status = status
  }
}

public struct VaporizeSimulationProvingGroundCoverageAudit: Codable, Equatable, Sendable {
  public var requiredScenarioSlugs: [String]
  public var coveredScenarioSlugs: [String]
  public var uncoveredScenarioSlugs: [String]
  public var unknownScenarioSlugs: [String]
  public var failingScenarioSlugs: [String]

  public var coverageStatus: String {
    uncoveredScenarioSlugs.isEmpty && unknownScenarioSlugs.isEmpty && failingScenarioSlugs.isEmpty
      ? "pass"
      : "fail"
  }
}

public enum VaporizeSimulationProvingGroundCoverageGate {
  public static func audit(
    manifest: VaporizeSimulationProvingGroundManifest,
    receipts: [VaporizeSimulationProvingGroundReceipt]
  ) -> VaporizeSimulationProvingGroundCoverageAudit {
    let required = manifest.scenarios.map(\.slug).sorted()
    let requiredSet = Set(required)
    let receiptSlugs = receipts.map(\.scenarioSlug)
    let receiptSet = Set(receiptSlugs)

    return VaporizeSimulationProvingGroundCoverageAudit(
      requiredScenarioSlugs: required,
      coveredScenarioSlugs: required.filter { receiptSet.contains($0) },
      uncoveredScenarioSlugs: required.filter { !receiptSet.contains($0) },
      unknownScenarioSlugs: receiptSet.filter { !requiredSet.contains($0) }.sorted(),
      failingScenarioSlugs: receipts
        .filter { $0.status != "pass" || $0.exitCode != 0 }
        .map(\.scenarioSlug)
        .sorted()
    )
  }
}
