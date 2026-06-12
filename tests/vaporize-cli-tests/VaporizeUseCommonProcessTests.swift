import CommonProcess
import Foundation
import Testing

@testable import VaporizeCLI

@Test("Decodes a CommonProcess CommandSpec for use mode")
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

@Test("Loads a CommonProcess CommandSpec from a file")
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

@Test("Rejects invalid CommonProcess CommandSpec for use mode")
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
