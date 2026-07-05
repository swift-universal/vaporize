import Foundation
import Testing
import SwiftJSONFormatter

@testable import VaporizeCLI

@Test("CUJ-06 Swift Universal formatter produces canonical JSON")
func swiftUniversalFormatterProducesCanonicalJSON() throws {
  let input = Data(#"{"b":1,"a":2,"url":"https://example.com"}"#.utf8)

  let output = try String(data: SwiftJSONFormatter.humanData(from: input), encoding: .utf8)

  let expected = """
    {
      "a" : 2,
      "b" : 1,
      "url" : "https://example.com"
    }
    """
  #expect(output == expected + "\n")
}

@Test("CUJ-06 validates JSON through Swift Universal JSON formatting")
func validatesJSONThroughSwiftUniversalJSONFormatting() throws {
  let data = Data(#"{"ok":true}"#.utf8)

  let receipt = try JSONValidation.validate(
    data: data,
    path: "fixture.json",
    requestId: "json-validation-test"
  )

  #expect(receipt.receiptKind == "vaporize-json-validation")
  #expect(receipt.valid)
  #expect(receipt.path == "fixture.json")
  #expect(receipt.requestId == "json-validation-test")
  #expect(receipt.byteCount == data.count)
  #expect(receipt.errorMessage == nil)
}

@Test("CUJ-06 rejects invalid JSON through Swift Universal JSON formatting")
func rejectsInvalidJSONThroughSwiftUniversalJSONFormatting() {
  let data = Data(#"{"ok":}"#.utf8)

  #expect(throws: Error.self) {
    _ = try JSONValidation.validate(
      data: data,
      path: "broken.json",
      requestId: "json-validation-test"
    )
  }
}
