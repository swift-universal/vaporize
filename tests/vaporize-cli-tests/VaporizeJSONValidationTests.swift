import Foundation
import Testing

@testable import VaporizeCLI

@Test("Validates JSON with Foundation")
func validatesJSONWithFoundation() throws {
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

@Test("Rejects invalid JSON with Foundation")
func rejectsInvalidJSONWithFoundation() {
  let data = Data(#"{"ok":}"#.utf8)

  #expect(throws: Error.self) {
    _ = try JSONValidation.validate(
      data: data,
      path: "broken.json",
      requestId: "json-validation-test"
    )
  }
}
