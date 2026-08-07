import Foundation
import Testing
@testable import VaporizeCLI
@testable import VaporizeIssueReporting

@Suite(.serialized)
struct VaporizeTestReceiptTests {
  @Test
  func coreExecutionReceiptRetainsBuildAndInstallTimingEnvelope() throws {
    let started = Date(timeIntervalSince1970: 1_700_000_000)
    let finished = started.addingTimeInterval(12.5)
    let receipt = VaporizeCoreExecutionReceipt(
      operation: "install",
      executionAuthority: "swift",
      toolchainResolver: "default-swift",
      packagePath: "/workspace/tool",
      product: "tool.cli",
      configuration: "debug",
      startedAt: started,
      finishedAt: finished,
      commandElapsedNanoseconds: 12_500_000_000,
      dependencyPreparationNanoseconds: 1_000_000_000,
      dependencyRestoreNanoseconds: 500_000_000,
      processExecutionNanoseconds: 11_000_000_000,
      succeeded: true,
      artifactPath: "/Users/example/.swiftpm/bin/tool.cli",
      failureDescription: nil
    )

    let decoded = try JSONDecoder().decode(
      VaporizeCoreExecutionReceipt.self,
      from: JSONEncoder().encode(receipt)
    )
    #expect(decoded == receipt)
    #expect(decoded.receiptKind == "vaporize-core-execution")
    #expect(decoded.processExecutionNanoseconds == 11_000_000_000)
  }

  @Test
  func absentSinkRecordsRunWithZeroIssues() throws {
    let fixture = try ReceiptFixture()
    defer { fixture.remove() }

    let ingestion = VaporizeTestIssueEventIngestor.ingest(from: fixture.sinkURL)
    let receipt = fixture.receipt(ingestion: ingestion)

    #expect(receipt.runtimeIssueExecution == "run")
    #expect(receipt.issueSinkState == .absent)
    #expect(receipt.unexpectedIssueCount == 0)
    #expect(receipt.expectedIssueCount == 0)
  }

  @Test
  func malformedSinkDoesNotClaimZeroIssues() throws {
    let fixture = try ReceiptFixture()
    defer { fixture.remove() }
    try FileManager.default.createDirectory(
      at: fixture.sinkURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try Data("{not-json}\n".utf8).write(to: fixture.sinkURL)

    let ingestion = VaporizeTestIssueEventIngestor.ingest(from: fixture.sinkURL)

    #expect(ingestion.state == .malformed)
    #expect(ingestion.events.isEmpty)
    #expect(ingestion.error == "issue sink line 1 is not a valid VaporizeIssueEvent")
  }

  @Test
  func duplicateEventIdentifiersAreCountedOnce() throws {
    let fixture = try ReceiptFixture()
    defer { fixture.remove() }
    let event = fixture.event(expected: false)
    let encoded = try VaporizeIssueEventCodec.encode(event)
    try FileManager.default.createDirectory(
      at: fixture.sinkURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    var sink = Data()
    sink.append(encoded)
    sink.append(0x0A)
    sink.append(encoded)
    sink.append(0x0A)
    try sink.write(to: fixture.sinkURL)

    let ingestion = VaporizeTestIssueEventIngestor.ingest(from: fixture.sinkURL)
    let receipt = fixture.receipt(ingestion: ingestion)

    #expect(ingestion.state == .valid)
    #expect(receipt.unexpectedIssueCount == 1)
    #expect(receipt.issueEvents.count == 1)
  }

  @Test
  func receiptSeparatesProcessAssertionExpectedAndUnexpectedOutcomes() throws {
    let fixture = try ReceiptFixture()
    defer { fixture.remove() }
    let ingestion = VaporizeTestIssueIngestion(
      state: .valid,
      events: [fixture.event(expected: false), fixture.event(expected: true, idSeed: 2)],
      error: nil
    )
    let receipt = fixture.receipt(
      ingestion: ingestion,
      succeeded: false,
      exitCode: 1,
      assertionOutcome: .detected
    )

    #expect(receipt.processOutcome == .nonzeroExit)
    #expect(receipt.testAssertionOutcome == .detected)
    #expect(receipt.unexpectedIssueCount == 1)
    #expect(receipt.expectedIssueCount == 1)
  }

  @Test
  func outputClassifierDistinguishesSwiftTestingFromProcessFailure() {
    #expect(
      VaporizeTestOutputClassifier.assertionOutcome(
        stdout: Data("Test run with 1 test failed".utf8),
        stderr: Data()
      ) == .detected
    )
    #expect(
      VaporizeTestOutputClassifier.assertionOutcome(
        stdout: Data("compiler process exited with status 1".utf8),
        stderr: Data()
      ) == .notDetected
    )
  }

  @Test
  func vaporizeCapturesSwiftTestingUnexpectedIssue() async throws {
    let receipt = try await runFixture(
      filter: "SwiftTestingUnexpectedTests",
      expectsProcessFailure: true
    )

    #expect(receipt.processOutcome == .nonzeroExit)
    #expect(receipt.testAssertionOutcome == .detected)
    #expect(receipt.issueSinkState == .valid)
    #expect(receipt.unexpectedIssueCount == 1)
    #expect(receipt.expectedIssueCount == 0)
    #expect(receipt.issueEvents.count == 1)
    #expect(receipt.issueEvents.first?.message == "fixture unexpected issue")
  }

  @Test
  func vaporizeRecordsExpectedIssueWithoutFailingTest() async throws {
    let receipt = try await runFixture(
      filter: "SwiftTestingExpectedTests",
      expectsProcessFailure: false
    )

    #expect(receipt.processOutcome == .succeeded)
    #expect(receipt.testAssertionOutcome == .notDetected)
    #expect(receipt.issueSinkState == .valid)
    #expect(receipt.unexpectedIssueCount == 0)
    #expect(receipt.expectedIssueCount == 1)
    #expect(receipt.issueEvents.first?.expected == true)
  }

  @Test
  func vaporizeGreenRunRecordsAbsentSinkAsZeroIssues() async throws {
    let receipt = try await runFixture(
      filter: "GreenTests",
      expectsProcessFailure: false
    )

    #expect(receipt.processOutcome == .succeeded)
    #expect(receipt.testAssertionOutcome == .notDetected)
    #expect(receipt.runtimeIssueExecution == "run")
    #expect(receipt.issueSinkState == .absent)
    #expect(receipt.unexpectedIssueCount == 0)
    #expect(receipt.expectedIssueCount == 0)
  }

  private func runFixture(
    filter: String,
    expectsProcessFailure: Bool
  ) async throws -> VaporizeTestReceipt {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-test-receipt-e2e-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: outputDirectory) }
    let receiptURL = outputDirectory.appendingPathComponent("test.receipt.json")

    var commandArguments = ["test"]
    #if os(macOS)
      commandArguments.append("swift")
    #endif
    commandArguments += [
      "--package-path", fixturePackageURL.path,
      "--product", "fixture.cli@vaporize-tests.clia.sh",
      "--configuration", "debug",
      "--receipt-path", receiptURL.path,
      "--",
      "--filter", filter,
    ]
    var command = try VaporizeCLI.parse(commandArguments)
    var failed = false
    do {
      try await command.run()
    } catch {
      failed = true
    }
    #expect(failed == expectsProcessFailure)

    let data = try Data(contentsOf: receiptURL)
    let receipt = try JSONDecoder().decode(VaporizeTestReceipt.self, from: data)
    #expect(receipt.schemaVersion == "0.3.0")
    #expect(receipt.operation == "test")
    #expect(receipt.executionAuthority == "swift")
    #expect(receipt.toolchainResolver == "default-swift")
    #expect(receipt.commandElapsedNanoseconds > 0)
    #expect(receipt.processExecutionNanoseconds > 0)
    #expect(
      receipt.commandElapsedNanoseconds
        >= receipt.dependencyPreparationNanoseconds
    )
    #expect(
      receipt.commandElapsedNanoseconds
        >= receipt.dependencyRestoreNanoseconds
    )
    #if os(macOS)
      #expect(
        receipt.alternateCommand
          == "vaporize.cli@wrkstrm-core.clia.sh test xcode"
      )
    #else
      #expect(receipt.alternateCommand == nil)
    #endif
    return receipt
  }

  private var fixturePackageURL: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("issue-reporting-fixtures", isDirectory: true)
  }
}

private struct ReceiptFixture {
  let directoryURL: URL
  let sinkURL: URL

  init() throws {
    directoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("vaporize-test-receipt-tests-\(UUID().uuidString)")
    sinkURL = directoryURL.appendingPathComponent("issues.jsonl")
  }

  func event(expected: Bool, idSeed: Int = 1) -> VaporizeIssueEvent {
    VaporizeIssueEvent(
      eventId: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", idSeed))!,
      occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
      severity: expected ? .info : .error,
      message: expected ? "Expected issue" : "Unexpected issue",
      fileId: "Fixture/Tests.swift",
      filePath: "<redacted>/Tests.swift",
      line: UInt(idSeed),
      column: 1,
      executionPhase: .test,
      vaporizeRequestId: "request-1",
      product: "fixture.cli@vaporize-tests.clia.sh",
      processId: 123,
      expected: expected,
      redactionSummary: "source-path"
    )
  }

  func receipt(
    ingestion: VaporizeTestIssueIngestion,
    succeeded: Bool = true,
    exitCode: Int? = 0,
    assertionOutcome: VaporizeTestAssertionOutcome = .notDetected
  ) -> VaporizeTestReceipt {
    VaporizeTestReceipt(
      packagePath: "/workspace/fixture",
      product: "fixture.cli@vaporize-tests.clia.sh",
      arguments: ["test"],
      operation: "test",
      executionAuthority: "swift",
      toolchainResolver: "default-swift",
      alternateCommand: "vaporize.cli@wrkstrm-core.clia.sh test xcode",
      commandElapsedNanoseconds: 400,
      dependencyPreparationNanoseconds: 100,
      dependencyRestoreNanoseconds: 50,
      processExecutionNanoseconds: 250,
      requestId: "request-1",
      runnerKind: "auto",
      succeeded: succeeded,
      exitCode: exitCode,
      signal: nil,
      stdoutBytes: 10,
      stderrBytes: 20,
      processIdentifier: "pid-1",
      processOutcome: VaporizeTestProcessOutcome(
        succeeded: succeeded,
        exitCode: exitCode,
        signal: nil
      ),
      testAssertionOutcome: assertionOutcome,
      issueSinkState: ingestion.state,
      issueSinkPath: sinkURL.path,
      issueIngestionError: ingestion.error,
      issueEvents: ingestion.events
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: directoryURL)
  }
}
