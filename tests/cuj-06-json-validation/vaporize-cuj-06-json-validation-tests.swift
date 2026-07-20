import Foundation
import SwiftJSONFormatter
import Testing

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
  let receipt = try JSONValidation.validate(data: data, path: "fixture.json", requestId: "json-validation-test")
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
    _ = try JSONValidation.validate(data: data, path: "broken.json", requestId: "json-validation-test")
  }
}

@Test("CUJ-06 schema validation receipt retains the command contract")
func schemaValidationReceiptRetainsCommandContract() {
  let receipt = JSONSchemaValidationReceipt(
    schemaPath: "schema.json",
    fixturePath: "fixture.json",
    requestId: "cuj-06-schema-validation-test",
    expected: "pass",
    actual: "pass",
    matched: true,
    diagnostics: [],
    nextSteps: []
  )
  #expect(receipt.receiptKind == "vaporize-json-schema-validation")
  #expect(receipt.matched == true)
}

@Test("CUJ-06 schema validation failures remain actionable")
func schemaValidationFailureMessageIsActionable() {
  let message = VaporizeCLIActionability.schemaValidationMessage(
    errorDescription: "actual outcome 'fail' did not match --expect pass",
    schemaPath: "schema.json",
    fixturePath: "fixture.json",
    expected: "pass",
    actual: "fail",
    diagnostics: ["/: contains — expected at least one array item to match the contained schema"]
  )
  #expect(message.contains("schema: schema.json"))
  #expect(message.contains("fixture: fixture.json"))
  #expect(message.contains("expected: pass"))
  #expect(message.contains("actual: fail"))
  #expect(message.contains("next:"))
  #expect(message.contains("digikoma: \(VaporizeCLIActionability.digikomaRef)"))
  #expect(message.contains("digikoma-command:"))
  #expect(message.contains(VaporizeCLIActionability.policyRef))
  #expect(message.contains(VaporizeCLIActionability.procedureRef))
}
