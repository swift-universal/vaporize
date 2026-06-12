import CommonProcess
import Foundation
import Testing

@testable import VaporizeCLI

@Test("CUJ-04 decodes a CommonProcess CommandSpec")
func decodesCommonProcessCommandSpecForUseMode() throws {
  let json = Data(
    """
    {
      "executable": {
        "ref": { "name": { "_0": "echo" } },
        "options": [],
        "arguments": []
      },
      "args": ["hello-use"],
      "requestId": "vaporize-use-test",
      "runnerKind": "foundation",
      "streamingMode": "buffered"
    }
    """.utf8
  )

  let command = try CommonProcessSpecLoader.decode(data: json)

  switch command.executable.ref {
  case .name(let name):
    #expect(name == "echo")
  default:
    Issue.record("expected executable name ref")
  }
  #expect(command.args == ["hello-use"])
  #expect(command.requestId == "vaporize-use-test")
  #expect(command.runnerKind == .foundation)
  #expect(command.streamingMode == .buffered)
}

@Test("CUJ-04 loads a CommonProcess CommandSpec from a file")
func loadsCommonProcessCommandSpecFromFile() throws {
  let fixture = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-use-spec-\(UUID().uuidString).json")
  defer { try? FileManager.default.removeItem(at: fixture) }
  try """
  {
    "executable": {
      "ref": { "path": { "_0": "/bin/echo" } },
      "options": [],
      "arguments": []
    },
    "args": ["from-file"],
    "requestId": "vaporize-use-file-test",
    "runnerKind": "auto",
    "streamingMode": "buffered"
  }
  """.write(to: fixture, atomically: true, encoding: .utf8)

  let command = try CommonProcessSpecLoader.load(path: fixture.path)

  switch command.executable.ref {
  case .path(let path):
    #expect(path == "/bin/echo")
  default:
    Issue.record("expected executable path ref")
  }
  #expect(command.args == ["from-file"])
  #expect(command.requestId == "vaporize-use-file-test")
}

@Test("CUJ-04 rejects invalid CommonProcess CommandSpec")
func rejectsInvalidCommonProcessCommandSpecForUseMode() {
  let json = Data(
    """
    {
      "executable": {
        "ref": { "name": { "_0": "" } },
        "options": [],
        "arguments": []
      }
    }
    """.utf8
  )

  #expect(throws: CommandSpecValidationError.self) {
    _ = try CommonProcessSpecLoader.decode(data: json)
  }
}

@Test("CUJ-04 use receipt records CommonProcess invocation shape")
func useReceiptRecordsCommonProcessInvocationShape() throws {
  let receipt = UseReceipt(
    specSource: "spec.json",
    executableRef: "name:echo",
    argumentCount: 1,
    workingDirectory: "/workspace/pkg",
    requestId: "vaporize-use-test",
    runnerKind: "foundation",
    streamingMode: "buffered",
    succeeded: true,
    exitCode: 0,
    signal: nil,
    stdoutBytes: 6,
    stderrBytes: 0,
    processIdentifier: "pid-3"
  )
  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(UseReceipt.self, from: data)

  #expect(decoded.schemaVersion == "0.1.0")
  #expect(decoded.receiptKind == "vaporize-use-common-process")
  #expect(decoded.specSource == "spec.json")
  #expect(decoded.executableRef == "name:echo")
  #expect(decoded.argumentCount == 1)
  #expect(decoded.streamingMode == "buffered")
}
