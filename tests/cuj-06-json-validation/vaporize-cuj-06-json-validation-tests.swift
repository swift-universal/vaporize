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

// MARK: - JSON Schema fixture validation
// [[FR-VAPORIZE-JSON-SCHEMA-FIXTURE-VALIDATION-2026-07-04]]

/// Walks up from this test file to the mono root so the schema-universal
/// workstream-schemas v0.0.4 proof fixtures resolve by absolute path.
private func monoRoot() throws -> URL {
  var url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
  while url.path != "/" {
    let marker = url.appendingPathComponent("private/universal/substrate/collectives")
    if FileManager.default.fileExists(atPath: marker.path) {
      return url
    }
    url.deleteLastPathComponent()
  }
  throw JSONSchemaValidation.EngineError.schemaLoadFailure(
    "cannot locate mono root above \(#filePath)")
}

private func workstreamSchemaFamilyRoot() throws -> URL {
  try monoRoot().appendingPathComponent(
    "private/universal/substrate/collectives/schema-universal/private/universal/domain/system/schema-families/workstream-schemas/v0.0.4"
  )
}

private func workstreamSchemaPath() throws -> String {
  try workstreamSchemaFamilyRoot().appendingPathComponent(
    "json/wrkstrm-workstream-schemas-v000-000-004/schemas/workstream/workstream.schema.json"
  ).path
}

private func fixturePath(_ name: String) throws -> String {
  try workstreamSchemaFamilyRoot().appendingPathComponent("fixtures/\(name)").path
}

@Test("CUJ-06 schema validation passes an expected-pass workstream fixture")
func schemaValidationPassesExpectedPassFixture() throws {
  let outcome = try JSONSchemaValidation.validate(
    schemaPath: try workstreamSchemaPath(),
    fixturePath: try fixturePath("canonical.valid-open-initiative.workstream.json")
  )

  #expect(outcome.valid)
  #expect(outcome.diagnostics.isEmpty)

  let receipt = JSONSchemaValidationReceipt(
    schemaPath: try workstreamSchemaPath(),
    fixturePath: try fixturePath("canonical.valid-open-initiative.workstream.json"),
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

@Test("CUJ-06 schema validation fails an expected-fail workstream fixture with diagnostics")
func schemaValidationFailsExpectedFailFixture() throws {
  let outcome = try JSONSchemaValidation.validate(
    schemaPath: try workstreamSchemaPath(),
    fixturePath: try fixturePath("invalid.ongoing-with-terminal-receipt.workstream.json")
  )

  #expect(!outcome.valid)
  #expect(!outcome.diagnostics.isEmpty)
  #expect(outcome.diagnostics.contains { $0.contains("/terminalReceiptRef") })
}

@Test("CUJ-06 schema validation detects expectation mismatch")
func schemaValidationDetectsExpectationMismatch() throws {
  let outcome = try JSONSchemaValidation.validate(
    schemaPath: try workstreamSchemaPath(),
    fixturePath: try fixturePath("invalid.continuity-class-mismatch.workstream.json")
  )
  #expect(!outcome.valid)

  let mismatch = JSONSchemaValidation.expectationOutcome(expected: "pass", valid: outcome.valid)
  #expect(mismatch.actual == "fail")
  #expect(mismatch.matched == false)

  let match = JSONSchemaValidation.expectationOutcome(expected: "fail", valid: outcome.valid)
  #expect(match.matched == true)

  let undeclared = JSONSchemaValidation.expectationOutcome(expected: nil, valid: outcome.valid)
  #expect(undeclared.actual == "fail")
  #expect(undeclared.matched == nil)
}

@Test("CUJ-06 actionable schema validation failure names paths, expectation, actual, next steps, and Digikoma")
func schemaValidationFailureMessageIsActionable() throws {
  let schemaPath = try workstreamSchemaPath()
  let fixture = try fixturePath("invalid.ongoing-with-terminal-receipt.workstream.json")

  let message = VaporizeCLIActionability.schemaValidationMessage(
    errorDescription: "actual outcome 'fail' did not match --expect pass",
    schemaPath: schemaPath,
    fixturePath: fixture,
    expected: "pass",
    actual: "fail",
    diagnostics: ["/terminalReceiptRef: type — expected null, got object"]
  )

  #expect(message.contains("schema: \(schemaPath)"))
  #expect(message.contains("fixture: \(fixture)"))
  #expect(message.contains("expected: pass"))
  #expect(message.contains("actual: fail"))
  #expect(message.contains("next:"))
  #expect(message.contains("digikoma: \(VaporizeCLIActionability.digikomaRef)"))
  #expect(message.contains("digikoma-command:"))
  #expect(message.contains(VaporizeCLIActionability.policyRef))
  #expect(message.contains(VaporizeCLIActionability.procedureRef))
}

@Test("CUJ-06 schema validation raises actionable error for remote $ref")
func schemaValidationRejectsRemoteRef() throws {
  let scratch = FileManager.default.temporaryDirectory
    .appendingPathComponent("cuj-06-remote-ref-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: scratch) }

  let schemaURL = scratch.appendingPathComponent("remote-ref.schema.json")
  try Data(#"{"$ref": "https://example.com/remote.schema.json"}"#.utf8).write(to: schemaURL)
  let fixtureURL = scratch.appendingPathComponent("fixture.json")
  try Data(#"{"ok": true}"#.utf8).write(to: fixtureURL)

  #expect(throws: JSONSchemaValidation.EngineError.self) {
    _ = try JSONSchemaValidation.validate(
      schemaPath: schemaURL.path,
      fixturePath: fixtureURL.path
    )
  }
}
