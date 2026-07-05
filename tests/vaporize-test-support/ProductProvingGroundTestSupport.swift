import Foundation

public struct VaporizeProductProvingGroundProfile: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var documentKind: String
  public var productSlug: String
  public var productClass: String
  public var owningBeadRef: String
  public var cujRefs: [String]
  public var requiredTrackSlugs: [String]
  public var scenarios: [VaporizeProductProvingGroundScenario]
  public var releaseDoctorCheckRefs: [String]
  public var metadata: [String: String]

  public init(
    schemaVersion: String = "0.1.0",
    documentKind: String = "vaporware-product-proving-ground-profile",
    productSlug: String,
    productClass: String,
    owningBeadRef: String,
    cujRefs: [String],
    requiredTrackSlugs: [String],
    scenarios: [VaporizeProductProvingGroundScenario],
    releaseDoctorCheckRefs: [String],
    metadata: [String: String] = [:]
  ) {
    self.schemaVersion = schemaVersion
    self.documentKind = documentKind
    self.productSlug = productSlug
    self.productClass = productClass
    self.owningBeadRef = owningBeadRef
    self.cujRefs = cujRefs
    self.requiredTrackSlugs = requiredTrackSlugs
    self.scenarios = scenarios
    self.releaseDoctorCheckRefs = releaseDoctorCheckRefs
    self.metadata = metadata
  }
}

public struct VaporizeProductProvingGroundScenario: Codable, Equatable, Sendable {
  public var slug: String
  public var title: String
  public var trackSlug: String
  public var proofKind: String
  public var maturity: String
  public var targetableTestBundle: String
  public var receiptRef: String

  public init(
    slug: String,
    title: String,
    trackSlug: String,
    proofKind: String,
    maturity: String,
    targetableTestBundle: String,
    receiptRef: String
  ) {
    self.slug = slug
    self.title = title
    self.trackSlug = trackSlug
    self.proofKind = proofKind
    self.maturity = maturity
    self.targetableTestBundle = targetableTestBundle
    self.receiptRef = receiptRef
  }
}

public struct VaporizeProductProvingGroundAdoptionAudit: Codable, Equatable, Sendable {
  public var requiredTrackSlugs: [String]
  public var coveredTrackSlugs: [String]
  public var missingTrackSlugs: [String]
  public var unknownTrackSlugs: [String]
  public var missingCUJRefs: [String]
  public var missingReceiptScenarioSlugs: [String]
  public var missingTargetableTestScenarioSlugs: [String]

  public var coverageStatus: String {
    missingTrackSlugs.isEmpty
      && unknownTrackSlugs.isEmpty
      && missingCUJRefs.isEmpty
      && missingReceiptScenarioSlugs.isEmpty
      && missingTargetableTestScenarioSlugs.isEmpty
      ? "pass"
      : "fail"
  }
}

public enum VaporizeProductProvingGroundAdoptionGate {
  public static let knownTrackSlugs = [
    "skid-pad",
    "hill-climb",
    "endurance-loop",
    "cold-start-chamber",
    "crash-barrier",
    "weather-track",
    "inspection-bay",
    "prototype-track",
  ]

  public static func requiredTracks(for productClass: String) -> [String] {
    switch productClass.lowercased() {
    case "cli":
      return [
        "cold-start-chamber",
        "hill-climb",
        "endurance-loop",
        "crash-barrier",
        "inspection-bay",
        "prototype-track",
      ]
    case "app":
      return [
        "cold-start-chamber",
        "hill-climb",
        "endurance-loop",
        "weather-track",
        "crash-barrier",
        "inspection-bay",
        "prototype-track",
      ]
    case "library":
      return [
        "hill-climb",
        "crash-barrier",
        "inspection-bay",
        "prototype-track",
      ]
    case "workflow":
      return [
        "skid-pad",
        "crash-barrier",
        "inspection-bay",
        "prototype-track",
      ]
    case "assistant":
      return [
        "weather-track",
        "crash-barrier",
        "inspection-bay",
        "prototype-track",
      ]
    case "site":
      return [
        "cold-start-chamber",
        "weather-track",
        "crash-barrier",
        "inspection-bay",
        "prototype-track",
      ]
    default:
      return [
        "crash-barrier",
        "inspection-bay",
        "prototype-track",
      ]
    }
  }

  public static func audit(
    profile: VaporizeProductProvingGroundProfile,
    requiredCUJRefs: [String] = []
  ) -> VaporizeProductProvingGroundAdoptionAudit {
    let requiredTrackSlugs = profile.requiredTrackSlugs.sorted()
    let requiredTrackSet = Set(requiredTrackSlugs)
    let scenarioTrackSlugs = profile.scenarios.map(\.trackSlug)
    let scenarioTrackSet = Set(scenarioTrackSlugs)
    let knownTrackSet = Set(knownTrackSlugs)
    let cujRefSet = Set(profile.cujRefs)

    return VaporizeProductProvingGroundAdoptionAudit(
      requiredTrackSlugs: requiredTrackSlugs,
      coveredTrackSlugs: requiredTrackSlugs.filter { scenarioTrackSet.contains($0) },
      missingTrackSlugs: requiredTrackSlugs.filter { !scenarioTrackSet.contains($0) },
      unknownTrackSlugs: scenarioTrackSet
        .filter { !knownTrackSet.contains($0) && !requiredTrackSet.contains($0) }
        .sorted(),
      missingCUJRefs: requiredCUJRefs.filter { !cujRefSet.contains($0) },
      missingReceiptScenarioSlugs: profile.scenarios
        .filter { $0.receiptRef.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .map(\.slug)
        .sorted(),
      missingTargetableTestScenarioSlugs: profile.scenarios
        .filter { $0.targetableTestBundle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .map(\.slug)
        .sorted()
    )
  }
}
