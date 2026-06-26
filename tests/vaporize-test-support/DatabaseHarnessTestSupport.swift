import Foundation

public struct VaporizeDatabaseHarnessSpec: Codable, Equatable, Sendable {
  public var identifier: String
  public var storage: VaporizeDatabaseHarnessStorage
  public var migrations: [String]
  public var seedStatements: [String]
  public var metadata: [String: String]

  public init(
    identifier: String,
    storage: VaporizeDatabaseHarnessStorage = .localLibSQLFile(fileName: "database.libsql"),
    migrations: [String] = [],
    seedStatements: [String] = [],
    metadata: [String: String] = [:]
  ) {
    self.identifier = identifier
    self.storage = storage
    self.migrations = migrations
    self.seedStatements = seedStatements
    self.metadata = metadata
  }
}

public enum VaporizeDatabaseHarnessStorage: Codable, Equatable, Sendable {
  case localLibSQLFile(fileName: String)
  case remoteTursoLibSQL(databaseURL: String, authTokenEnvironmentVariable: String)

  public var mode: String {
    switch self {
    case .localLibSQLFile:
      return "local-libsql-file"
    case .remoteTursoLibSQL:
      return "remote-turso-libsql"
    }
  }

  public var requiresNetwork: Bool {
    switch self {
    case .localLibSQLFile:
      return false
    case .remoteTursoLibSQL:
      return true
    }
  }
}

public struct VaporizeDatabaseHarnessInstance: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var harnessKind: String
  public var identifier: String
  public var storageMode: String
  public var rootPath: String
  public var databaseURL: String
  public var migrationScriptPath: String
  public var seedScriptPath: String
  public var receiptPath: String
  public var migrationCount: Int
  public var seedStatementCount: Int
  public var requiresNetwork: Bool
  public var metadata: [String: String]
  public var createdAt: String

  public init(
    schemaVersion: String,
    harnessKind: String,
    identifier: String,
    storageMode: String,
    rootPath: String,
    databaseURL: String,
    migrationScriptPath: String,
    seedScriptPath: String,
    receiptPath: String,
    migrationCount: Int,
    seedStatementCount: Int,
    requiresNetwork: Bool,
    metadata: [String: String],
    createdAt: String
  ) {
    self.schemaVersion = schemaVersion
    self.harnessKind = harnessKind
    self.identifier = identifier
    self.storageMode = storageMode
    self.rootPath = rootPath
    self.databaseURL = databaseURL
    self.migrationScriptPath = migrationScriptPath
    self.seedScriptPath = seedScriptPath
    self.receiptPath = receiptPath
    self.migrationCount = migrationCount
    self.seedStatementCount = seedStatementCount
    self.requiresNetwork = requiresNetwork
    self.metadata = metadata
    self.createdAt = createdAt
  }
}

public struct VaporizeDatabaseTestHarness {
  public var rootDirectory: URL
  public var fileManager: FileManager

  public init(
    rootDirectory: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-database-harness-\(UUID().uuidString)"),
    fileManager: FileManager = .default
  ) {
    self.rootDirectory = rootDirectory
    self.fileManager = fileManager
  }

  public func prepare(
    _ spec: VaporizeDatabaseHarnessSpec,
    createdAt: Date = Date()
  ) throws -> VaporizeDatabaseHarnessInstance {
    let fixtureRoot = rootDirectory.appendingPathComponent(slug(for: spec.identifier), isDirectory: true)
    try fileManager.createDirectory(at: fixtureRoot, withIntermediateDirectories: true)

    let migrationURL = fixtureRoot.appendingPathComponent("migrations.sql")
    let seedURL = fixtureRoot.appendingPathComponent("seed.sql")
    let receiptURL = fixtureRoot.appendingPathComponent("database-harness-receipt.json")

    try spec.migrations.joined(separator: "\n\n").write(to: migrationURL, atomically: true, encoding: .utf8)
    try spec.seedStatements.joined(separator: "\n\n").write(to: seedURL, atomically: true, encoding: .utf8)

    let databaseURL = try materializeDatabaseURL(storage: spec.storage, in: fixtureRoot)
    let instance = VaporizeDatabaseHarnessInstance(
      schemaVersion: "0.1.0",
      harnessKind: "turso-like-database-test-harness",
      identifier: spec.identifier,
      storageMode: spec.storage.mode,
      rootPath: fixtureRoot.path,
      databaseURL: databaseURL,
      migrationScriptPath: migrationURL.path,
      seedScriptPath: seedURL.path,
      receiptPath: receiptURL.path,
      migrationCount: spec.migrations.count,
      seedStatementCount: spec.seedStatements.count,
      requiresNetwork: spec.storage.requiresNetwork,
      metadata: spec.metadata,
      createdAt: Self.timestampString(from: createdAt)
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(instance).write(to: receiptURL)
    return instance
  }

  private func materializeDatabaseURL(
    storage: VaporizeDatabaseHarnessStorage,
    in fixtureRoot: URL
  ) throws -> String {
    switch storage {
    case .localLibSQLFile(let fileName):
      let databaseURL = fixtureRoot.appendingPathComponent(fileName)
      if fileManager.fileExists(atPath: databaseURL.path) == false {
        try Data().write(to: databaseURL)
      }
      return databaseURL.absoluteString
    case .remoteTursoLibSQL(let databaseURL, _):
      return databaseURL
    }
  }

  private func slug(for identifier: String) -> String {
    let pieces = identifier.lowercased().map { character -> Character in
      if character.isLetter || character.isNumber {
        return character
      }
      return "-"
    }
    let slug = String(pieces)
      .split(separator: "-")
      .joined(separator: "-")
    return slug.isEmpty ? "database-fixture" : slug
  }

  private static func timestampString(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }
}
