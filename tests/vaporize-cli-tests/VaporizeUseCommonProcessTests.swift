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
