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

public struct VaporizeKuraWorldSeedStateSpec: Codable, Equatable, Sendable {
  public var worldSlug: String
  public var worldTitle: String
  public var cujs: [VaporizeCriticalUserJourney]
  public var metadata: [String: String]

  public init(
    worldSlug: String,
    worldTitle: String,
    cujs: [VaporizeCriticalUserJourney],
    metadata: [String: String] = [:]
  ) {
    self.worldSlug = worldSlug
    self.worldTitle = worldTitle
    self.cujs = cujs
    self.metadata = metadata
  }
}

public struct VaporizeKuraWorldSeedDocument: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var documentKind: String
  public var worldSlug: String
  public var worldTitle: String
  public var sourceKind: String
  public var records: [VaporizeKuraWorldSeedRecord]
  public var metadata: [String: String]
  public var createdAt: String
}

public struct VaporizeKuraWorldSeedRecord: Codable, Equatable, Sendable {
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

public struct VaporizeKuraWorldSeedStateReceipt: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var harnessKind: String
  public var storageFamily: String
  public var worldSlug: String
  public var rootPath: String
  public var cujManifestPath: String
  public var seedStatePath: String
  public var receiptPath: String
  public var cujCount: Int
  public var seedRecordCount: Int
  public var sourceKind: String
  public var metadata: [String: String]
  public var createdAt: String

  public init(
    schemaVersion: String,
    harnessKind: String,
    storageFamily: String,
    worldSlug: String,
    rootPath: String,
    cujManifestPath: String,
    seedStatePath: String,
    receiptPath: String,
    cujCount: Int,
    seedRecordCount: Int,
    sourceKind: String,
    metadata: [String: String],
    createdAt: String
  ) {
    self.schemaVersion = schemaVersion
    self.harnessKind = harnessKind
    self.storageFamily = storageFamily
    self.worldSlug = worldSlug
    self.rootPath = rootPath
    self.cujManifestPath = cujManifestPath
    self.seedStatePath = seedStatePath
    self.receiptPath = receiptPath
    self.cujCount = cujCount
    self.seedRecordCount = seedRecordCount
    self.sourceKind = sourceKind
    self.metadata = metadata
    self.createdAt = createdAt
  }
}

public struct VaporizeKuraWorldSeedStateHarness {
  public var rootDirectory: URL
  public var fileManager: FileManager

  public init(
    rootDirectory: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-kura-world-seed-state-\(UUID().uuidString)"),
    fileManager: FileManager = .default
  ) {
    self.rootDirectory = rootDirectory
    self.fileManager = fileManager
  }

  public func prepare(
    _ spec: VaporizeKuraWorldSeedStateSpec,
    createdAt: Date = Date()
  ) throws -> VaporizeKuraWorldSeedStateReceipt {
    let normalizedWorldSlug = slug(for: spec.worldSlug)
    let worldRoot = rootDirectory.appendingPathComponent(normalizedWorldSlug, isDirectory: true)
    try fileManager.createDirectory(at: worldRoot, withIntermediateDirectories: true)

    let cujManifestURL = worldRoot.appendingPathComponent("cujs.json")
    let seedStateURL = worldRoot.appendingPathComponent("kura-world.seed-state.json")
    let receiptURL = worldRoot.appendingPathComponent("kura-world.seed-state.receipt.json")
    let createdAtString = Self.timestampString(from: createdAt)

    let records = spec.cujs.map { cuj in
      seedRecord(for: cuj, worldSlug: normalizedWorldSlug)
    }
    let seedDocument = VaporizeKuraWorldSeedDocument(
      schemaVersion: "0.1.0",
      documentKind: "kura-world-seed-state",
      worldSlug: normalizedWorldSlug,
      worldTitle: spec.worldTitle,
      sourceKind: "critical-user-journey",
      records: records,
      metadata: spec.metadata,
      createdAt: createdAtString
    )
    let receipt = VaporizeKuraWorldSeedStateReceipt(
      schemaVersion: "0.1.0",
      harnessKind: "kura-world-seed-state-harness",
      storageFamily: "kura",
      worldSlug: normalizedWorldSlug,
      rootPath: worldRoot.path,
      cujManifestPath: cujManifestURL.path,
      seedStatePath: seedStateURL.path,
      receiptPath: receiptURL.path,
      cujCount: spec.cujs.count,
      seedRecordCount: records.count,
      sourceKind: "critical-user-journey",
      metadata: spec.metadata,
      createdAt: createdAtString
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(spec.cujs).write(to: cujManifestURL)
    try encoder.encode(seedDocument).write(to: seedStateURL)
    try encoder.encode(receipt).write(to: receiptURL)
    return receipt
  }

  private func seedRecord(
    for cuj: VaporizeCriticalUserJourney,
    worldSlug: String
  ) -> VaporizeKuraWorldSeedRecord {
    let normalizedCUJSlug = slug(for: cuj.slug)
    return VaporizeKuraWorldSeedRecord(
      id: "\(worldSlug).cuj.\(normalizedCUJSlug)",
      kind: "critical-user-journey-seed",
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
    return slug.isEmpty ? "kura-world" : slug
  }

  private static func timestampString(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }
}
