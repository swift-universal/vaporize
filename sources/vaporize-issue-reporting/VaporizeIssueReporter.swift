import Foundation
import IssueReporting

public struct VaporizeIssueReporter: IssueReporter, Sendable {
  public struct Configuration: Sendable {
    public let sinkURL: URL
    public let executionPhase: VaporizeIssueEvent.ExecutionPhase
    public let vaporizeRequestId: String
    public let product: String
    public let includeAbsoluteSourcePath: Bool
    public let messageCharacterLimit: Int

    public init(
      sinkURL: URL,
      executionPhase: VaporizeIssueEvent.ExecutionPhase,
      vaporizeRequestId: String,
      product: String,
      includeAbsoluteSourcePath: Bool = false,
      messageCharacterLimit: Int = 4_096
    ) {
      self.sinkURL = sinkURL
      self.executionPhase = executionPhase
      self.vaporizeRequestId = vaporizeRequestId
      self.product = product
      self.includeAbsoluteSourcePath = includeAbsoluteSourcePath
      self.messageCharacterLimit = max(0, messageCharacterLimit)
    }
  }

  private let configuration: Configuration
  private let sink: JSONLFileSink
  private let now: @Sendable () -> Date
  private let makeEventId: @Sendable () -> UUID
  private let processId: Int32
  private let homeDirectoryPath: String?
  private let reportsAreExpected: Bool

  public init(configuration: Configuration) {
    self.init(
      configuration: configuration,
      now: { Date() },
      makeEventId: { UUID() },
      processId: ProcessInfo.processInfo.processIdentifier,
      homeDirectoryPath: FileManager.default.homeDirectoryForCurrentUser.path,
      reportsAreExpected: false
    )
  }

  init(
    configuration: Configuration,
    now: @escaping @Sendable () -> Date,
    makeEventId: @escaping @Sendable () -> UUID,
    processId: Int32,
    homeDirectoryPath: String?,
    reportsAreExpected: Bool = false
  ) {
    self.configuration = configuration
    self.sink = JSONLFileSink(url: configuration.sinkURL)
    self.now = now
    self.makeEventId = makeEventId
    self.processId = processId
    self.homeDirectoryPath = homeDirectoryPath
    self.reportsAreExpected = reportsAreExpected
  }

  public func reportIssue(
    _ message: @autoclosure () -> String?,
    severity: IssueSeverity,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    if reportsAreExpected {
      emit(
        message: message() ?? "Issue expected",
        severity: .info,
        expected: true,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return
    }

    let eventSeverity: VaporizeIssueEvent.Severity
    switch severity {
    case .warning:
      eventSeverity = .warning
    case .error:
      eventSeverity = .error
    }
    emit(
      message: message() ?? "Issue reported",
      severity: eventSeverity,
      expected: false,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  public func expectIssue(
    _ message: @autoclosure () -> String?,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    emit(
      message: message() ?? "Issue expected",
      severity: .info,
      expected: true,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  private func emit(
    message: String,
    severity: VaporizeIssueEvent.Severity,
    expected: Bool,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    var redactions: [String] = []
    var redactedMessage = redactHomeDirectory(in: message, redactions: &redactions)
    if redactedMessage.count > configuration.messageCharacterLimit {
      redactedMessage = String(redactedMessage.prefix(configuration.messageCharacterLimit))
      redactions.append("message-truncated")
    }

    let sourcePath = redactSourcePath(String(describing: filePath), redactions: &redactions)
    let event = VaporizeIssueEvent(
      eventId: makeEventId(),
      occurredAt: now(),
      severity: severity,
      message: redactedMessage,
      fileId: String(describing: fileID),
      filePath: sourcePath,
      line: line,
      column: column,
      executionPhase: configuration.executionPhase,
      vaporizeRequestId: configuration.vaporizeRequestId,
      product: configuration.product,
      processId: processId,
      expected: expected,
      redactionSummary: redactions.isEmpty ? "none" : redactions.joined(separator: ",")
    )

    do {
      try sink.append(VaporizeIssueEventCodec.encode(event))
    } catch {
      let fallbackError = error as NSError
      JSONLFileSink.writeFallback(
        "vaporize issue reporter could not append event "
          + "(sink=<redacted>/\(configuration.sinkURL.lastPathComponent), "
          + "domain=\(fallbackError.domain), code=\(fallbackError.code))\n"
      )
    }
  }

  private func redactHomeDirectory(in value: String, redactions: inout [String]) -> String {
    guard let homeDirectoryPath, !homeDirectoryPath.isEmpty, value.contains(homeDirectoryPath)
    else { return value }
    redactions.append("home-directory")
    return value.replacingOccurrences(of: homeDirectoryPath, with: "<home>")
  }

  private func redactSourcePath(_ sourcePath: String, redactions: inout [String]) -> String {
    guard configuration.includeAbsoluteSourcePath else {
      redactions.append("source-path")
      return "<redacted>/\(URL(fileURLWithPath: sourcePath).lastPathComponent)"
    }
    return redactHomeDirectory(in: sourcePath, redactions: &redactions)
  }
}

public enum VaporizeIssueReporting {
  public static let sinkPathEnvironmentKey = "VAPORIZE_ISSUE_REPORT_PATH"
  public static let requestIdEnvironmentKey = "VAPORIZE_REQUEST_ID"
  public static let executionPhaseEnvironmentKey = "VAPORIZE_EXECUTION_PHASE"

  public static func configurationFromEnvironment(
    product: String,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> VaporizeIssueReporter.Configuration? {
    guard
      let rawSinkPath = environment[sinkPathEnvironmentKey], !rawSinkPath.isEmpty,
      let requestId = environment[requestIdEnvironmentKey], !requestId.isEmpty,
      let rawPhase = environment[executionPhaseEnvironmentKey],
      let phase = VaporizeIssueEvent.ExecutionPhase(rawValue: rawPhase)
    else { return nil }

    return VaporizeIssueReporter.Configuration(
      sinkURL: URL(fileURLWithPath: rawSinkPath),
      executionPhase: phase,
      vaporizeRequestId: requestId,
      product: product
    )
  }

  @discardableResult
  public static func installFromEnvironment(
    product: String,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> Bool {
    guard let configuration = configurationFromEnvironment(
      product: product,
      environment: environment
    ) else { return false }
    install(configuration: configuration)
    return true
  }

  public static func install(configuration: VaporizeIssueReporter.Configuration) {
    IssueReporters.current.append(VaporizeIssueReporter(configuration: configuration))
  }

  public static func withReporter<R>(
    configuration: VaporizeIssueReporter.Configuration,
    operation: () throws -> R
  ) rethrows -> R {
    try withIssueReporters(
      IssueReporters.current + [VaporizeIssueReporter(configuration: configuration)],
      operation: operation
    )
  }

  public static func withExpectedReporter<R>(
    configuration: VaporizeIssueReporter.Configuration,
    operation: () throws -> R
  ) rethrows -> R {
    try withIssueReporters(
      IssueReporters.current + [
        VaporizeIssueReporter(
          configuration: configuration,
          now: { Date() },
          makeEventId: { UUID() },
          processId: ProcessInfo.processInfo.processIdentifier,
          homeDirectoryPath: FileManager.default.homeDirectoryForCurrentUser.path,
          reportsAreExpected: true
        )
      ],
      operation: operation
    )
  }

  public static func withReporter<R>(
    configuration: VaporizeIssueReporter.Configuration,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await withIssueReporters(
      IssueReporters.current + [VaporizeIssueReporter(configuration: configuration)],
      operation: operation
    )
  }

  public static func withExpectedReporter<R>(
    configuration: VaporizeIssueReporter.Configuration,
    operation: () async throws -> R
  ) async rethrows -> R {
    try await withIssueReporters(
      IssueReporters.current + [
        VaporizeIssueReporter(
          configuration: configuration,
          now: { Date() },
          makeEventId: { UUID() },
          processId: ProcessInfo.processInfo.processIdentifier,
          homeDirectoryPath: FileManager.default.homeDirectoryForCurrentUser.path,
          reportsAreExpected: true
        )
      ],
      operation: operation
    )
  }
}

private final class JSONLFileSink: @unchecked Sendable {
  private let url: URL
  private let lock = NSLock()

  init(url: URL) {
    self.url = url
  }

  func append(_ encodedEvent: Data) throws {
    lock.lock()
    defer { lock.unlock() }

    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    if !FileManager.default.fileExists(atPath: url.path) {
      guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
        throw CocoaError(.fileWriteUnknown)
      }
    }

    let handle = try FileHandle(forWritingTo: url)
    defer { try? handle.close() }
    try handle.seekToEnd()
    try handle.write(contentsOf: encodedEvent)
    try handle.write(contentsOf: Data([0x0A]))
  }

  static func writeFallback(_ message: String) {
    guard let data = message.data(using: .utf8) else { return }
    try? FileHandle.standardError.write(contentsOf: data)
  }
}
