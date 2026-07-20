import Foundation
import VaporizeIssueReporting

enum VaporizeTestIssueSinkState: String, Codable, Equatable, Sendable {
  case absent
  case valid
  case malformed
}

enum VaporizeTestProcessOutcome: String, Codable, Equatable, Sendable {
  case succeeded
  case nonzeroExit = "nonzero-exit"
  case signaled
  case unavailable

  init(succeeded: Bool, exitCode: Int?, signal: Int?) {
    if succeeded {
      self = .succeeded
    } else if signal != nil {
      self = .signaled
    } else if exitCode != nil {
      self = .nonzeroExit
    } else {
      self = .unavailable
    }
  }
}

enum VaporizeTestAssertionOutcome: String, Codable, Equatable, Sendable {
  case notDetected = "not-detected"
  case detected
}

struct VaporizeTestIssueIngestion: Equatable, Sendable {
  var state: VaporizeTestIssueSinkState
  var events: [VaporizeIssueEvent]
  var error: String?
}

enum VaporizeTestIssueEventIngestor {
  static func ingest(from url: URL) -> VaporizeTestIssueIngestion {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return VaporizeTestIssueIngestion(state: .absent, events: [], error: nil)
    }

    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      return VaporizeTestIssueIngestion(
        state: .malformed,
        events: [],
        error: "issue sink could not be read"
      )
    }

    var events: [VaporizeIssueEvent] = []
    var seenEventIds: Set<UUID> = []
    for (index, line) in data.split(separator: 0x0A).enumerated() {
      do {
        let event = try VaporizeIssueEventCodec.decode(Data(line))
        guard event.schemaVersion == VaporizeIssueEvent.currentSchemaVersion else {
          return VaporizeTestIssueIngestion(
            state: .malformed,
            events: [],
            error: "issue sink line \(index + 1) uses an unsupported schema version"
          )
        }
        if seenEventIds.insert(event.eventId).inserted {
          events.append(event)
        }
      } catch {
        return VaporizeTestIssueIngestion(
          state: .malformed,
          events: [],
          error: "issue sink line \(index + 1) is not a valid VaporizeIssueEvent"
        )
      }
    }
    return VaporizeTestIssueIngestion(state: .valid, events: events, error: nil)
  }
}

enum VaporizeTestOutputClassifier {
  static func assertionOutcome(stdout: Data, stderr: Data) -> VaporizeTestAssertionOutcome {
    let output = String(decoding: stdout + stderr, as: UTF8.self)
    let swiftTestingFailure = output.contains("Test run with") && output.contains("failed")
    return swiftTestingFailure ? .detected : .notDetected
  }
}

struct VaporizeTestReceipt: Codable, Equatable, Sendable {
  var schemaVersion = "0.3.0"
  var receiptKind = "vaporize-test-execution"
  var packagePath: String
  /// Present when the test run names an installable product. Library-only
  /// package tests are intentionally productless.
  var product: String?
  var arguments: [String]
  var operation: String
  var executionAuthority: String
  var toolchainResolver: String
  var alternateCommand: String?
  var commandElapsedNanoseconds: UInt64
  var dependencyPreparationNanoseconds: UInt64
  var dependencyRestoreNanoseconds: UInt64
  var processExecutionNanoseconds: UInt64
  var requestId: String
  var runnerKind: String
  var succeeded: Bool
  var exitCode: Int?
  var signal: Int?
  var stdoutBytes: Int
  var stderrBytes: Int
  var processIdentifier: String?
  var processOutcome: VaporizeTestProcessOutcome
  var testAssertionOutcome: VaporizeTestAssertionOutcome
  var runtimeIssueExecution = "run"
  var issueSinkState: VaporizeTestIssueSinkState
  var issueSinkPath: String?
  var issueIngestionError: String?
  var unexpectedIssueCount: Int
  var expectedIssueCount: Int
  var issueEvents: [VaporizeIssueEvent]

  init(
    packagePath: String,
    product: String?,
    arguments: [String],
    operation: String,
    executionAuthority: String,
    toolchainResolver: String,
    alternateCommand: String?,
    commandElapsedNanoseconds: UInt64,
    dependencyPreparationNanoseconds: UInt64,
    dependencyRestoreNanoseconds: UInt64,
    processExecutionNanoseconds: UInt64,
    requestId: String,
    runnerKind: String,
    succeeded: Bool,
    exitCode: Int?,
    signal: Int?,
    stdoutBytes: Int,
    stderrBytes: Int,
    processIdentifier: String?,
    processOutcome: VaporizeTestProcessOutcome,
    testAssertionOutcome: VaporizeTestAssertionOutcome,
    issueSinkState: VaporizeTestIssueSinkState,
    issueSinkPath: String?,
    issueIngestionError: String?,
    issueEvents: [VaporizeIssueEvent]
  ) {
    self.packagePath = packagePath
    self.product = product
    self.arguments = arguments
    self.operation = operation
    self.executionAuthority = executionAuthority
    self.toolchainResolver = toolchainResolver
    self.alternateCommand = alternateCommand
    self.commandElapsedNanoseconds = commandElapsedNanoseconds
    self.dependencyPreparationNanoseconds = dependencyPreparationNanoseconds
    self.dependencyRestoreNanoseconds = dependencyRestoreNanoseconds
    self.processExecutionNanoseconds = processExecutionNanoseconds
    self.requestId = requestId
    self.runnerKind = runnerKind
    self.succeeded = succeeded
    self.exitCode = exitCode
    self.signal = signal
    self.stdoutBytes = stdoutBytes
    self.stderrBytes = stderrBytes
    self.processIdentifier = processIdentifier
    self.processOutcome = processOutcome
    self.testAssertionOutcome = testAssertionOutcome
    self.issueSinkState = issueSinkState
    self.issueSinkPath = issueSinkPath
    self.issueIngestionError = issueIngestionError
    self.unexpectedIssueCount = issueEvents.count { !$0.expected }
    self.expectedIssueCount = issueEvents.count { $0.expected }
    self.issueEvents = issueEvents
  }
}
