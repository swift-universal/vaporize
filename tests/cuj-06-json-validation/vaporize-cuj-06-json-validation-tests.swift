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

private func spawnRequestSchemaPath() throws -> String {
  try monoRoot().appendingPathComponent(
    "private/universal/substrate/collectives/schema-universal/private/universal/domain/platforms/schema-families/spawn-vaporware-packet-schemas/v0.0.5/json/spawn-vaporware-packet-schemas-v000-000-005/schemas/spawn-request-packet/spawn-request-packet.schema.json"
  ).path
}

private func ontologyInspectorSpawnRequestPath() throws -> String {
  try monoRoot().appendingPathComponent(
    "private/universal/substrate/collectives/wrkstrm/private/universal/kura-spaces/workstream/formula/spawn-vaporware/instances/schema-universal-ontology-inspector.spawn-request-packet.json"
  ).path
}

private func validateSchemaLiteral(
  _ schema: String,
  fixture: String
) throws -> JSONSchemaValidation.Outcome {
  let scratch = FileManager.default.temporaryDirectory
    .appendingPathComponent("cuj-06-schema-keywords-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: scratch) }

  let schemaURL = scratch.appendingPathComponent("schema.json")
  try Data(schema.utf8).write(to: schemaURL)
  let fixtureURL = scratch.appendingPathComponent("fixture.json")
  try Data(fixture.utf8).write(to: fixtureURL)
  return try JSONSchemaValidation.validate(
    schemaPath: schemaURL.path,
    fixturePath: fixtureURL.path
  )
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

@Test(
  "CUJ-06 actionable schema validation failure names paths, expectation, actual, next steps, and Digikoma"
)
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

@Test("CUJ-06 schema validation enforces numeric, object, and string constraints")
func schemaValidationEnforcesNumericMaximum() throws {
  let scratch = FileManager.default.temporaryDirectory
    .appendingPathComponent("cuj-06-maximum-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: scratch) }

  let schemaURL = scratch.appendingPathComponent("maximum.schema.json")
  try Data(#"{"type":"integer","minimum":1,"maximum":3}"#.utf8).write(to: schemaURL)
  let passingURL = scratch.appendingPathComponent("passing.json")
  try Data("3".utf8).write(to: passingURL)
  let failingURL = scratch.appendingPathComponent("failing.json")
  try Data("4".utf8).write(to: failingURL)

  let passing = try JSONSchemaValidation.validate(
    schemaPath: schemaURL.path,
    fixturePath: passingURL.path
  )
  let failing = try JSONSchemaValidation.validate(
    schemaPath: schemaURL.path,
    fixturePath: failingURL.path
  )

  #expect(passing.valid)
  #expect(!failing.valid)
  #expect(failing.diagnostics.contains { $0.contains("maximum") })

  let objectSchemaURL = scratch.appendingPathComponent("min-properties.schema.json")
  try Data(#"{"type":"object","minProperties":1}"#.utf8).write(to: objectSchemaURL)
  let populatedObjectURL = scratch.appendingPathComponent("populated-object.json")
  try Data(#"{"proof":true}"#.utf8).write(to: populatedObjectURL)
  let emptyObjectURL = scratch.appendingPathComponent("empty-object.json")
  try Data("{}".utf8).write(to: emptyObjectURL)

  let populatedObject = try JSONSchemaValidation.validate(
    schemaPath: objectSchemaURL.path,
    fixturePath: populatedObjectURL.path
  )
  let emptyObject = try JSONSchemaValidation.validate(
    schemaPath: objectSchemaURL.path,
    fixturePath: emptyObjectURL.path
  )

  #expect(populatedObject.valid)
  #expect(!emptyObject.valid)
  #expect(emptyObject.diagnostics.contains { $0.contains("minProperties") })

  let patternSchemaURL = scratch.appendingPathComponent("pattern.schema.json")
  try Data(#"{"type":"string","pattern":"^CUJ-[0-9][0-9]$"}"#.utf8).write(
    to: patternSchemaURL
  )
  let matchingStringURL = scratch.appendingPathComponent("matching-string.json")
  try Data(#""CUJ-26""#.utf8).write(to: matchingStringURL)
  let nonmatchingStringURL = scratch.appendingPathComponent("nonmatching-string.json")
  try Data(#""cuj-26""#.utf8).write(to: nonmatchingStringURL)

  let matchingString = try JSONSchemaValidation.validate(
    schemaPath: patternSchemaURL.path,
    fixturePath: matchingStringURL.path
  )
  let nonmatchingString = try JSONSchemaValidation.validate(
    schemaPath: patternSchemaURL.path,
    fixturePath: nonmatchingStringURL.path
  )

  #expect(matchingString.valid)
  #expect(!nonmatchingString.valid)
  #expect(nonmatchingString.diagnostics.contains { $0.contains("pattern") })
}

@Test("CUJ-06 schema validation enforces uniqueItems with deep JSON equality")
func schemaValidationEnforcesDeepUniqueItems() throws {
  let unique = try validateSchemaLiteral(
    #"{"type":"array","uniqueItems":true}"#,
    fixture: #"[{"value":[1,true]},{"value":[true,1]}]"#
  )
  #expect(unique.valid)

  let duplicate = try validateSchemaLiteral(
    #"{"type":"array","uniqueItems":true}"#,
    fixture:
      #"[{"nested":{"proof":[1,true]},"other":null},{"other":null,"nested":{"proof":[1.0,true]}}]"#
  )
  #expect(!duplicate.valid)
  #expect(duplicate.diagnostics.contains { $0.contains("uniqueItems") })
  #expect(duplicate.diagnostics.contains { $0.contains("indexes 0 and 1") })

  let booleanAndNumber = try validateSchemaLiteral(
    #"{"type":"array","uniqueItems":true}"#,
    fixture: "[true,1,false,0]"
  )
  #expect(booleanAndNumber.valid)

  let integersBeyondBinary64Precision = try validateSchemaLiteral(
    #"{"type":"array","uniqueItems":true}"#,
    fixture: "[9007199254740992,9007199254740993]"
  )
  #expect(integersBeyondBinary64Precision.valid)

  let equalExponentAndExpandedNumber = try validateSchemaLiteral(
    #"{"type":"array","uniqueItems":true}"#,
    fixture: "[1e20,100000000000000000000]"
  )
  #expect(!equalExponentAndExpandedNumber.valid)

  let disabled = try validateSchemaLiteral(
    #"{"type":"array","uniqueItems":false}"#,
    fixture: #"[{"proof":true},{"proof":true}]"#
  )
  #expect(disabled.valid)
}

@Test("CUJ-06 schema validation enforces exact array cardinality")
func schemaValidationEnforcesArrayCardinality() throws {
  let schema = #"{"type":"array","minItems":2,"maxItems":2}"#
  let exact = try validateSchemaLiteral(schema, fixture: #"["report","reconciliation"]"#)
  let tooFew = try validateSchemaLiteral(schema, fixture: #"["report"]"#)
  let tooMany = try validateSchemaLiteral(
    schema,
    fixture: #"["report","reconciliation","issue"]"#
  )

  #expect(exact.valid)
  #expect(!tooFew.valid)
  #expect(tooFew.diagnostics.contains { $0.contains("minItems") })
  #expect(!tooMany.valid)
  #expect(tooMany.diagnostics.contains { $0.contains("maxItems") })
}

@Test("CUJ-06 schema validation enforces contains and accepts the owned Spawn request")
func schemaValidationEnforcesContains() throws {
  let schema = #"{"type":"array","contains":{"const":"SwiftUI"}}"#
  let matching = try validateSchemaLiteral(schema, fixture: #"["Foundation","SwiftUI"]"#)
  let missing = try validateSchemaLiteral(schema, fixture: #"["Foundation","Darwin"]"#)

  #expect(matching.valid)
  #expect(!missing.valid)
  #expect(missing.diagnostics.contains { $0.contains("contains") })

  let spawnRequest = try JSONSchemaValidation.validate(
    schemaPath: try spawnRequestSchemaPath(),
    fixturePath: try ontologyInspectorSpawnRequestPath()
  )
  #expect(spawnRequest.valid)
  #expect(spawnRequest.diagnostics.isEmpty)
}

@Test("CUJ-06 schema validation accepts only RFC 3339 date-time strings")
func schemaValidationEnforcesRFC3339DateTimeFormat() throws {
  let schema = #"{"format":"date-time"}"#
  let validValues = [
    #""1963-06-19T08:30:06.283185Z""#,
    #""1937-01-01T12:00:27.87+00:20""#,
    #""1963-06-19t08:30:06z""#,
    #""1998-12-31T15:59:60.123-08:00""#,
    "12",
  ]
  for value in validValues {
    let outcome = try validateSchemaLiteral(schema, fixture: value)
    #expect(outcome.valid)
  }

  let invalidValues = [
    #""1990-02-31T15:59:59.123-08:00""#,
    #""1990-12-31T24:00:00Z""#,
    #""1990-12-31T10:00:00+10:60""#,
    #""1998-12-31T23:58:60Z""#,
    #""2013-350T01:01:01Z""#,
    #""+11963-06-19T08:30:06Z""#,
  ]
  for value in invalidValues {
    let outcome = try validateSchemaLiteral(schema, fixture: value)
    #expect(!outcome.valid)
    #expect(outcome.diagnostics.contains { $0.contains("RFC 3339 date-time") })
  }
}

@Test("CUJ-06 schema validation fails loudly for unsupported formats")
func schemaValidationRejectsUnsupportedFormat() throws {
  do {
    _ = try validateSchemaLiteral(
      #"{"format":"uuid"}"#,
      fixture: #""346d9d9a-6c83-4533-9974-37d29d2294a8""#
    )
    #expect(Bool(false))
  } catch let error as JSONSchemaValidation.EngineError {
    guard case .unsupportedSchemaFeature(let detail) = error else {
      #expect(Bool(false))
      return
    }
    #expect(detail.contains("format 'uuid'"))
  }
}
