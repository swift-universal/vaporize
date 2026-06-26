import Foundation

public struct VaporizeCriticalUserJourney: Codable, Equatable, Sendable {
  public var slug: String
  public var title: String
  public var actor: String
  public var intent: String
  public var preconditions: [String]
  public var actions: [String]
  public var outcomes: [String]
  public var tags: [String]
  public var metadata: [String: String]

  public init(
    slug: String,
    title: String,
    actor: String,
    intent: String,
    preconditions: [String] = [],
    actions: [String] = [],
    outcomes: [String] = [],
    tags: [String] = [],
    metadata: [String: String] = [:]
  ) {
    self.slug = slug
    self.title = title
    self.actor = actor
    self.intent = intent
    self.preconditions = preconditions
    self.actions = actions
    self.outcomes = outcomes
    self.tags = tags
    self.metadata = metadata
  }
}

public struct VaporizeCUJStateSpec: Codable, Equatable, Sendable {
  public var stateSlug: String
  public var stateTitle: String
  public var cujs: [VaporizeCriticalUserJourney]
  public var metadata: [String: String]

  public init(
    stateSlug: String,
    stateTitle: String,
    cujs: [VaporizeCriticalUserJourney],
    metadata: [String: String] = [:]
  ) {
    self.stateSlug = stateSlug
    self.stateTitle = stateTitle
    self.cujs = cujs
    self.metadata = metadata
  }
}

public struct VaporizeCUJStateDocument: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var documentKind: String
  public var stateSlug: String
  public var stateTitle: String
  public var sourceKind: String
  public var records: [VaporizeCUJStateRecord]
  public var metadata: [String: String]
  public var createdAt: String
}

public struct VaporizeCUJStateRecord: Codable, Equatable, Sendable {
  public var id: String
  public var kind: String
  public var sourceCUJSlug: String
  public var title: String
  public var actor: String
  public var intent: String
  public var preconditions: [String]
  public var actions: [String]
  public var outcomes: [String]
  public var tags: [String]
  public var metadata: [String: String]
}

public struct VaporizeCUJStateReceipt: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var harnessKind: String
  public var stateFamily: String
  public var storehouseFamily: String?
  public var stateSlug: String
  public var rootPath: String
  public var cujManifestPath: String
  public var statePath: String
  public var receiptPath: String
  public var cujCount: Int
  public var stateRecordCount: Int
  public var sourceKind: String
  public var metadata: [String: String]
  public var createdAt: String

  public init(
    schemaVersion: String,
    harnessKind: String,
    stateFamily: String,
    storehouseFamily: String?,
    stateSlug: String,
    rootPath: String,
    cujManifestPath: String,
    statePath: String,
    receiptPath: String,
    cujCount: Int,
    stateRecordCount: Int,
    sourceKind: String,
    metadata: [String: String],
    createdAt: String
  ) {
    self.schemaVersion = schemaVersion
    self.harnessKind = harnessKind
    self.stateFamily = stateFamily
    self.storehouseFamily = storehouseFamily
    self.stateSlug = stateSlug
    self.rootPath = rootPath
    self.cujManifestPath = cujManifestPath
    self.statePath = statePath
    self.receiptPath = receiptPath
    self.cujCount = cujCount
    self.stateRecordCount = stateRecordCount
    self.sourceKind = sourceKind
    self.metadata = metadata
    self.createdAt = createdAt
  }
}

public struct VaporizeCUJStateProof: Codable, Equatable, Sendable {
  public var stateID: String
  public var proofKind: String
  public var testTarget: String
  public var testName: String
  public var receiptRef: String

  public init(
    stateID: String,
    proofKind: String,
    testTarget: String,
    testName: String,
    receiptRef: String
  ) {
    self.stateID = stateID
    self.proofKind = proofKind
    self.testTarget = testTarget
    self.testName = testName
    self.receiptRef = receiptRef
  }
}

public struct VaporizeCUJStateCoverageAudit: Codable, Equatable, Sendable {
  public var requiredStateIDs: [String]
  public var coveredStateIDs: [String]
  public var uncoveredStateIDs: [String]
  public var unknownStateIDs: [String]
  public var duplicateProofStateIDs: [String]

  public var isPassing: Bool {
    uncoveredStateIDs.isEmpty && unknownStateIDs.isEmpty
  }
}

public struct VaporizeCUJStateCoverageManifest: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var documentKind: String
  public var stateFamily: String
  public var stateSlug: String
  public var statePath: String
  public var requiredStateIDs: [String]
  public var proofs: [VaporizeCUJStateProof]
  public var coveredStateIDs: [String]
  public var uncoveredStateIDs: [String]
  public var unknownStateIDs: [String]
  public var duplicateProofStateIDs: [String]
  public var coverageStatus: String
  public var createdAt: String
}

public enum VaporizeCUJStateCoverageGate {
  public static func audit(
    document: VaporizeCUJStateDocument,
    proofs: [VaporizeCUJStateProof]
  ) -> VaporizeCUJStateCoverageAudit {
    let required = document.records.map(\.id).sorted()
    let requiredSet = Set(required)
    let proofIDs = proofs.map(\.stateID)
    let proofSet = Set(proofIDs)
    let duplicates = Dictionary(grouping: proofIDs, by: { $0 })
      .filter { $0.value.count > 1 }
      .map(\.key)
      .sorted()

    return VaporizeCUJStateCoverageAudit(
      requiredStateIDs: required,
      coveredStateIDs: required.filter { proofSet.contains($0) },
      uncoveredStateIDs: required.filter { !proofSet.contains($0) },
      unknownStateIDs: proofSet.filter { !requiredSet.contains($0) }.sorted(),
      duplicateProofStateIDs: duplicates
    )
  }

  public static func manifest(
    document: VaporizeCUJStateDocument,
    statePath: String,
    proofs: [VaporizeCUJStateProof],
    createdAt: Date = Date()
  ) -> VaporizeCUJStateCoverageManifest {
    let audit = audit(document: document, proofs: proofs)
    return VaporizeCUJStateCoverageManifest(
      schemaVersion: "0.1.0",
      documentKind: "cuj-state-coverage",
      stateFamily: "cuj-state",
      stateSlug: document.stateSlug,
      statePath: statePath,
      requiredStateIDs: audit.requiredStateIDs,
      proofs: proofs,
      coveredStateIDs: audit.coveredStateIDs,
      uncoveredStateIDs: audit.uncoveredStateIDs,
      unknownStateIDs: audit.unknownStateIDs,
      duplicateProofStateIDs: audit.duplicateProofStateIDs,
      coverageStatus: audit.isPassing ? "pass" : "fail",
      createdAt: timestampString(from: createdAt)
    )
  }
}

public struct VaporizeCUJStateHarness {
  public var rootDirectory: URL
  public var storehouseFamily: String?
  public var fileManager: FileManager

  public init(
    rootDirectory: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-cuj-state-\(UUID().uuidString)"),
    storehouseFamily: String? = nil,
    fileManager: FileManager = .default
  ) {
    self.rootDirectory = rootDirectory
    self.storehouseFamily = storehouseFamily
    self.fileManager = fileManager
  }

  public func prepare(
    _ spec: VaporizeCUJStateSpec,
    createdAt: Date = Date()
  ) throws -> VaporizeCUJStateReceipt {
    let normalizedStateSlug = slug(for: spec.stateSlug)
    let stateRoot = rootDirectory.appendingPathComponent(normalizedStateSlug, isDirectory: true)
    try fileManager.createDirectory(at: stateRoot, withIntermediateDirectories: true)

    let cujManifestURL = stateRoot.appendingPathComponent("cujs.json")
    let stateURL = stateRoot.appendingPathComponent("cuj-state.json")
    let receiptURL = stateRoot.appendingPathComponent("cuj-state.receipt.json")
    let createdAtString = Self.timestampString(from: createdAt)

    let records = spec.cujs.map { cuj in
      stateRecord(for: cuj, stateSlug: normalizedStateSlug)
    }
    let stateDocument = VaporizeCUJStateDocument(
      schemaVersion: "0.1.0",
      documentKind: "cuj-state",
      stateSlug: normalizedStateSlug,
      stateTitle: spec.stateTitle,
      sourceKind: "critical-user-journey",
      records: records,
      metadata: spec.metadata,
      createdAt: createdAtString
    )
    let receipt = VaporizeCUJStateReceipt(
      schemaVersion: "0.1.0",
      harnessKind: "cuj-state-harness",
      stateFamily: "cuj-state",
      storehouseFamily: storehouseFamily,
      stateSlug: normalizedStateSlug,
      rootPath: stateRoot.path,
      cujManifestPath: cujManifestURL.path,
      statePath: stateURL.path,
      receiptPath: receiptURL.path,
      cujCount: spec.cujs.count,
      stateRecordCount: records.count,
      sourceKind: "critical-user-journey",
      metadata: spec.metadata,
      createdAt: createdAtString
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(spec.cujs).write(to: cujManifestURL)
    try encoder.encode(stateDocument).write(to: stateURL)
    try encoder.encode(receipt).write(to: receiptURL)
    return receipt
  }

  public func writeCoverageManifest(
    document: VaporizeCUJStateDocument,
    statePath: String,
    proofs: [VaporizeCUJStateProof],
    createdAt: Date = Date()
  ) throws -> URL {
    let stateURL = URL(fileURLWithPath: statePath)
    let coverageURL = stateURL.deletingLastPathComponent().appendingPathComponent("cuj-state.coverage.json")
    let manifest = VaporizeCUJStateCoverageGate.manifest(
      document: document,
      statePath: statePath,
      proofs: proofs,
      createdAt: createdAt
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(manifest).write(to: coverageURL)
    return coverageURL
  }

  private func stateRecord(
    for cuj: VaporizeCriticalUserJourney,
    stateSlug: String
  ) -> VaporizeCUJStateRecord {
    let normalizedCUJSlug = slug(for: cuj.slug)
    return VaporizeCUJStateRecord(
      id: "\(stateSlug).cuj.\(normalizedCUJSlug)",
      kind: "critical-user-journey-state",
      sourceCUJSlug: normalizedCUJSlug,
      title: cuj.title,
      actor: cuj.actor,
      intent: cuj.intent,
      preconditions: cuj.preconditions,
      actions: cuj.actions,
      outcomes: cuj.outcomes,
      tags: cuj.tags,
      metadata: cuj.metadata
    )
  }

  private func slug(for value: String) -> String {
    let pieces = value.lowercased().map { character -> Character in
      if character.isLetter || character.isNumber {
        return character
      }
      return "-"
    }
    let slug = String(pieces)
      .split(separator: "-")
      .joined(separator: "-")
    return slug.isEmpty ? "cuj-state" : slug
  }

  private static func timestampString(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }
}

private func timestampString(from date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter.string(from: date)
}
