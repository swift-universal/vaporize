import Foundation
import IssueReporting
import Testing
@testable import VaporizeIssueReporting

@Suite(.serialized)
struct VaporizeIssueReporterTests {
  @Test
  func eventRoundTripsThroughStableCodec() throws {
    let event = VaporizeIssueEvent(
      eventId: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
      occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
      severity: .warning,
      message: "Recoverable invariant",
      fileId: "Example/Example.swift",
      filePath: "<redacted>/Example.swift",
      line: 42,
      column: 7,
      executionPhase: .test,
      vaporizeRequestId: "request-1",
      product: "Example",
      processId: 123,
      expected: false,
      redactionSummary: "source-path"
    )

    let decoded = try VaporizeIssueEventCodec.decode(VaporizeIssueEventCodec.encode(event))
    #expect(decoded == event)
    #expect(decoded.schemaVersion == "0.1.0")
  }

  @Test
  func unexpectedAndExpectedIssuesRemainDistinguishable() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let reporter = fixture.reporter()

    reporter.reportIssue(
      "Connection state recovered",
      severity: .warning,
      fileID: "IRC/IRCClient.swift",
      filePath: "/workspace/Sources/IRC/IRCClient.swift",
      line: 211,
      column: 9
    )
    reporter.expectIssue(
      "Known disconnect during shutdown",
      fileID: "IRC/IRCClient.swift",
      filePath: "/workspace/Sources/IRC/IRCClient.swift",
      line: 227,
      column: 9
    )

    let events = try fixture.events()
    #expect(events.count == 2)
    #expect(events[0].severity == .warning)
    #expect(events[0].expected == false)
    #expect(events[0].filePath == "<redacted>/IRCClient.swift")
    #expect(events[1].severity == .info)
    #expect(events[1].expected == true)
  }

  @Test
  func redactsHomeAndSourcePathAndTruncatesMessage() throws {
    let fixture = try Fixture(messageCharacterLimit: 18)
    defer { fixture.remove() }
    let reporter = fixture.reporter(homeDirectoryPath: "/Users/tester")

    reporter.reportIssue(
      "Token at /Users/tester/private/credential should never persist",
      severity: .error,
      fileID: "Secrets/Secret.swift",
      filePath: "/Users/tester/project/Secret.swift",
      line: 10,
      column: 2
    )

    let event = try #require(fixture.events().first)
    #expect(!event.message.contains("/Users/tester"))
    #expect(event.message.count == 18)
    #expect(event.filePath == "<redacted>/Secret.swift")
    #expect(event.redactionSummary == "home-directory,message-truncated,source-path")
  }

  @Test
  func concurrentReportsProduceCompleteJSONLines() async throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let reporter = fixture.reporter()

    await withTaskGroup(of: Void.self) { group in
      for index in 0..<32 {
        group.addTask {
          reporter.reportIssue(
            "Concurrent issue \(index)",
            severity: .warning,
            fileID: "Concurrency/Test.swift",
            filePath: "/workspace/Concurrency/Test.swift",
            line: UInt(index + 1),
            column: 1
          )
        }
      }
    }

    let events = try fixture.events()
    #expect(events.count == 32)
    #expect(Set(events.map(\.line)) == Set((1...32).map(UInt.init)))
  }

  @Test
  func environmentConfigurationRequiresSinkRequestAndValidPhase() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let environment = [
      VaporizeIssueReporting.sinkPathEnvironmentKey: fixture.sinkURL.path,
      VaporizeIssueReporting.requestIdEnvironmentKey: "request-from-environment",
      VaporizeIssueReporting.executionPhaseEnvironmentKey: "run",
    ]

    let configuration = try #require(
      VaporizeIssueReporting.configurationFromEnvironment(
        product: "ExampleApp",
        environment: environment
      )
    )
    #expect(configuration.sinkURL == fixture.sinkURL)
    #expect(configuration.vaporizeRequestId == "request-from-environment")
    #expect(configuration.executionPhase == .run)
    #expect(
      VaporizeIssueReporting.configurationFromEnvironment(
        product: "ExampleApp",
        environment: [VaporizeIssueReporting.executionPhaseEnvironmentKey: "build"]
      ) == nil
    )
  }

  @Test
  func installAppendsInsteadOfReplacingCurrentReporters() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    withIssueReporters([NoopReporter()]) {
      #expect(IssueReporters.current.count == 1)
      VaporizeIssueReporting.install(configuration: fixture.configuration)
      #expect(IssueReporters.current.count == 2)
    }
  }

  @Test
  func sinkFailureReturnsWithoutRecursiveIssueReporting() throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try FileManager.default.createDirectory(
      at: fixture.sinkURL,
      withIntermediateDirectories: true
    )

    fixture.reporter().reportIssue(
      "The sink path is intentionally a directory",
      severity: .warning,
      fileID: "Sink/Failure.swift",
      filePath: "/workspace/Sink/Failure.swift",
      line: 1,
      column: 1
    )

    #expect(FileManager.default.fileExists(atPath: fixture.sinkURL.path))
  }
}

private struct NoopReporter: IssueReporter {
  func reportIssue(
    _ message: @autoclosure () -> String?,
    severity: IssueSeverity,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {}
}

private struct Fixture {
  let directoryURL: URL
  let sinkURL: URL
  let configuration: VaporizeIssueReporter.Configuration

  init(messageCharacterLimit: Int = 4_096) throws {
    directoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-issue-reporting-tests-\(UUID().uuidString)")
    sinkURL = directoryURL.appendingPathComponent("issues.jsonl")
    configuration = VaporizeIssueReporter.Configuration(
      sinkURL: sinkURL,
      executionPhase: .test,
      vaporizeRequestId: "request-1",
      product: "VaporizeIssueReportingTests",
      messageCharacterLimit: messageCharacterLimit
    )
  }

  func reporter(homeDirectoryPath: String? = "/Users/tester") -> VaporizeIssueReporter {
    VaporizeIssueReporter(
      configuration: configuration,
      now: { Date(timeIntervalSince1970: 1_700_000_000) },
      makeEventId: { UUID() },
      processId: 123,
      homeDirectoryPath: homeDirectoryPath
    )
  }

  func events() throws -> [VaporizeIssueEvent] {
    let data = try Data(contentsOf: sinkURL)
    return try data.split(separator: 0x0A).map {
      try VaporizeIssueEventCodec.decode(Data($0))
    }
  }

  func remove() {
    try? FileManager.default.removeItem(at: directoryURL)
  }
}
