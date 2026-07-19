import Foundation

public struct VaporizeIssueEvent: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = "0.1.0"

  public enum Severity: String, Codable, Sendable {
    case info
    case warning
    case error
  }

  public enum ExecutionPhase: String, Codable, Sendable {
    case test
    case run
  }

  public let schemaVersion: String
  public let eventId: UUID
  public let occurredAt: Date
  public let severity: Severity
  public let message: String
  public let fileId: String
  public let filePath: String
  public let line: UInt
  public let column: UInt
  public let executionPhase: ExecutionPhase
  public let vaporizeRequestId: String
  public let product: String
  public let processId: Int32
  public let expected: Bool
  public let redactionSummary: String

  public init(
    schemaVersion: String = Self.currentSchemaVersion,
    eventId: UUID,
    occurredAt: Date,
    severity: Severity,
    message: String,
    fileId: String,
    filePath: String,
    line: UInt,
    column: UInt,
    executionPhase: ExecutionPhase,
    vaporizeRequestId: String,
    product: String,
    processId: Int32,
    expected: Bool,
    redactionSummary: String
  ) {
    self.schemaVersion = schemaVersion
    self.eventId = eventId
    self.occurredAt = occurredAt
    self.severity = severity
    self.message = message
    self.fileId = fileId
    self.filePath = filePath
    self.line = line
    self.column = column
    self.executionPhase = executionPhase
    self.vaporizeRequestId = vaporizeRequestId
    self.product = product
    self.processId = processId
    self.expected = expected
    self.redactionSummary = redactionSummary
  }
}

public enum VaporizeIssueEventCodec {
  public static func encode(_ event: VaporizeIssueEvent) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(event)
  }

  public static func decode(_ data: Data) throws -> VaporizeIssueEvent {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(VaporizeIssueEvent.self, from: data)
  }
}
