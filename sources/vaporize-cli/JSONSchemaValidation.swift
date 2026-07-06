import Foundation

/// Minimal, self-contained JSON Schema draft-2020-12 subset validator for
/// `validate-json-schema` mode. See
/// ``beads/FR-VAPORIZE-JSON-SCHEMA-FIXTURE-VALIDATION-2026-07-04``.
///
/// Supported vocabulary: `type`, `properties`, `required`,
/// `additionalProperties`, `const`, `enum`, `allOf`, `anyOf`, `oneOf`,
/// `if`/`then`/`else`, `items`, `minItems`, `minLength`, `minimum`, `$defs`,
/// and `$ref` for internal pointers (`#/$defs/...`) plus local relative-file
/// refs resolved against the referring schema file's directory. Remote
/// `http(s)` refs are an explicit non-goal and raise an actionable
/// unsupported-schema-feature error instead of silently passing.
enum JSONSchemaValidation {

  /// Structured engine result. The engine reports validity plus
  /// JSON-pointer-ish diagnostics; expectation matching is the CLI's job.
  struct Outcome: Equatable {
    var valid: Bool
    var diagnostics: [String]
  }

  enum EngineError: Error, CustomStringConvertible, Equatable {
    case unsupportedSchemaFeature(String)
    case schemaLoadFailure(String)
    case schemaParseFailure(String)
    case fixtureParseFailure(String)

    var description: String {
      switch self {
      case .unsupportedSchemaFeature(let detail):
        return "unsupported schema feature: \(detail)"
      case .schemaLoadFailure(let detail):
        return "schema load failure: \(detail)"
      case .schemaParseFailure(let detail):
        return "schema parse failure: \(detail)"
      case .fixtureParseFailure(let detail):
        return "fixture parse failure: \(detail)"
      }
    }
  }

  /// JSON value model with explicit null so `const`/`enum` comparisons
  /// against JSON null stay honest.
  indirect enum Value: Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([Value])
    case object([String: Value])

    init(data: Data, sourceDescription: String) throws {
      let raw: Any
      do {
        raw = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
      } catch {
        throw EngineError.fixtureParseFailure("\(sourceDescription): \(error.localizedDescription)")
      }
      self.init(raw: raw)
    }

    init(raw: Any) {
      switch raw {
      case is NSNull:
        self = .null
      case let number as NSNumber:
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
          self = .bool(number.boolValue)
        } else {
          self = .number(number.doubleValue)
        }
      case let string as String:
        self = .string(string)
      case let array as [Any]:
        self = .array(array.map(Value.init(raw:)))
      case let dictionary as [String: Any]:
        self = .object(dictionary.mapValues(Value.init(raw:)))
      default:
        // JSONSerialization only produces the cases above; keep a loud
        // fallback instead of silently coercing unexpected runtime values.
        self = .string(String(describing: raw))
      }
    }

    var typeName: String {
      switch self {
      case .null: return "null"
      case .bool: return "boolean"
      case .number: return "number"
      case .string: return "string"
      case .array: return "array"
      case .object: return "object"
      }
    }
  }

  /// Validates the fixture instance at `fixturePath` against the schema file
  /// at `schemaPath`. Throws ``EngineError`` on schema/fixture parse
  /// failures, unresolvable refs, remote refs, and unsupported keywords.
  static func validate(schemaPath: String, fixturePath: String) throws -> Outcome {
    let validator = Validator()
    let (schemaDocument, canonicalSchemaPath) = try validator.loadSchemaDocument(
      at: URL(fileURLWithPath: schemaPath)
    )

    let fixtureURL = URL(fileURLWithPath: fixturePath)
    let fixtureData: Data
    do {
      fixtureData = try Data(contentsOf: fixtureURL)
    } catch {
      throw EngineError.fixtureParseFailure(
        "cannot read fixture at \(fixturePath): \(error.localizedDescription)")
    }
    let instance = try Value(data: fixtureData, sourceDescription: "invalid JSON at \(fixturePath)")

    var diagnostics: [String] = []
    let valid = try validator.validate(
      schema: schemaDocument,
      instance: instance,
      context: Validator.Context(documentPath: canonicalSchemaPath, documentRoot: schemaDocument),
      instancePath: "",
      diagnostics: &diagnostics
    )
    return Outcome(valid: valid, diagnostics: diagnostics)
  }

  /// Maps engine validity plus an optional declared expectation to the
  /// receipt's actual label and expectation match. `matched` is nil when no
  /// expectation was declared.
  static func expectationOutcome(expected: String?, valid: Bool) -> (
    actual: String, matched: Bool?
  ) {
    let actual = valid ? "pass" : "fail"
    guard let expected else { return (actual, nil) }
    return (actual, expected == actual)
  }

  final class Validator {
    struct Context {
      var documentPath: String
      var documentRoot: Value
    }

    /// Loaded schema documents keyed by canonical file path so shared refs
    /// (for example link-ref-model) are read once and ref cycles are
    /// detectable against stable identities.
    private var documentCache: [String: Value] = [:]
    /// Active `$ref` frames (`document#fragment@instancePath`) used to guard
    /// against cyclic refs on the same instance location.
    private var activeRefFrames: Set<String> = []

    private static let handledKeywords: Set<String> = [
      "$ref", "type", "properties", "required", "additionalProperties",
      "const", "enum", "allOf", "anyOf", "oneOf", "if", "then", "else",
      "items", "minItems", "minLength", "minimum",
    ]
    private static let ignoredAnnotationKeywords: Set<String> = [
      "$schema", "$id", "$defs", "title", "description", "$comment",
      "examples", "default", "deprecated", "readOnly", "writeOnly",
    ]

    func loadSchemaDocument(at url: URL) throws -> (Value, String) {
      let canonicalPath = url.standardizedFileURL.resolvingSymlinksInPath().path
      if let cached = documentCache[canonicalPath] {
        return (cached, canonicalPath)
      }
      guard FileManager.default.fileExists(atPath: canonicalPath) else {
        throw JSONSchemaValidation.EngineError.schemaLoadFailure(
          "schema file not found at \(canonicalPath)")
      }
      let data: Data
      do {
        data = try Data(contentsOf: URL(fileURLWithPath: canonicalPath))
      } catch {
        throw JSONSchemaValidation.EngineError.schemaLoadFailure(
          "cannot read schema at \(canonicalPath): \(error.localizedDescription)")
      }
      let raw: Any
      do {
        raw = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
      } catch {
        throw JSONSchemaValidation.EngineError.schemaParseFailure(
          "invalid JSON in schema at \(canonicalPath): \(error.localizedDescription)")
      }
      let document = Value(raw: raw)
      documentCache[canonicalPath] = document
      return (document, canonicalPath)
    }

    // swift-format-ignore: FunctionBodyLength
    func validate(
      schema: Value,
      instance: Value,
      context: Context,
      instancePath: String,
      diagnostics: inout [String]
    ) throws -> Bool {
      switch schema {
      case .bool(true):
        return true
      case .bool(false):
        diagnostics.append("\(pointerLabel(instancePath)): schema false — no value is allowed here")
        return false
      case .object(let keywords):
        return try validate(
          keywords: keywords,
          instance: instance,
          context: context,
          instancePath: instancePath,
          diagnostics: &diagnostics
        )
      default:
        throw JSONSchemaValidation.EngineError.schemaParseFailure(
          "schema value in \(context.documentPath) must be an object or boolean, got \(schema.typeName)"
        )
      }
    }

    // swift-format-ignore: FunctionBodyLength, CyclomaticComplexity
    private func validate(
      keywords: [String: Value],
      instance: Value,
      context: Context,
      instancePath: String,
      diagnostics: inout [String]
    ) throws -> Bool {
      for keyword in keywords.keys
      where !Self.handledKeywords.contains(keyword)
        && !Self.ignoredAnnotationKeywords.contains(keyword)
      {
        throw JSONSchemaValidation.EngineError.unsupportedSchemaFeature(
          "keyword '\(keyword)' in \(context.documentPath) (instance path \(pointerLabel(instancePath)))"
        )
      }

      var valid = true
      let pointer = pointerLabel(instancePath)

      if let refKeyword = keywords["$ref"] {
        guard case .string(let ref) = refKeyword else {
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'$ref' in \(context.documentPath) must be a string")
        }
        valid =
          try validateRef(
            ref,
            instance: instance,
            context: context,
            instancePath: instancePath,
            diagnostics: &diagnostics
          ) && valid
      }

      if let typeKeyword = keywords["type"] {
        let allowed: [String]
        switch typeKeyword {
        case .string(let name):
          allowed = [name]
        case .array(let names):
          allowed = names.compactMap { if case .string(let name) = $0 { name } else { nil } }
        default:
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'type' in \(context.documentPath) must be a string or array of strings")
        }
        if !allowed.contains(where: { matchesType(instance, typeName: $0) }) {
          diagnostics.append(
            "\(pointer): type — expected \(allowed.joined(separator: " or ")), got \(instance.typeName)"
          )
          valid = false
        }
      }

      if let constKeyword = keywords["const"], instance != constKeyword {
        diagnostics.append("\(pointer): const — value does not equal required constant")
        valid = false
      }

      if let enumKeyword = keywords["enum"] {
        guard case .array(let candidates) = enumKeyword else {
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'enum' in \(context.documentPath) must be an array")
        }
        if !candidates.contains(instance) {
          diagnostics.append("\(pointer): enum — value is not one of the allowed values")
          valid = false
        }
      }

      valid =
        try validateObjectKeywords(
          keywords: keywords,
          instance: instance,
          context: context,
          instancePath: instancePath,
          diagnostics: &diagnostics
        ) && valid

      valid =
        try validateArrayAndScalarKeywords(
          keywords: keywords,
          instance: instance,
          context: context,
          instancePath: instancePath,
          diagnostics: &diagnostics
        ) && valid

      valid =
        try validateCombinators(
          keywords: keywords,
          instance: instance,
          context: context,
          instancePath: instancePath,
          diagnostics: &diagnostics
        ) && valid

      return valid
    }

    private func validateObjectKeywords(
      keywords: [String: Value],
      instance: Value,
      context: Context,
      instancePath: String,
      diagnostics: inout [String]
    ) throws -> Bool {
      guard case .object(let members) = instance else { return true }
      var valid = true
      let pointer = pointerLabel(instancePath)

      var declaredProperties: [String: Value] = [:]
      if let propertiesKeyword = keywords["properties"] {
        guard case .object(let propertySchemas) = propertiesKeyword else {
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'properties' in \(context.documentPath) must be an object")
        }
        declaredProperties = propertySchemas
        for (name, propertySchema) in propertySchemas.sorted(by: { $0.key < $1.key }) {
          guard let memberValue = members[name] else { continue }
          valid =
            try validate(
              schema: propertySchema,
              instance: memberValue,
              context: context,
              instancePath: "\(instancePath)/\(name)",
              diagnostics: &diagnostics
            ) && valid
        }
      }

      if let requiredKeyword = keywords["required"] {
        guard case .array(let requiredNames) = requiredKeyword else {
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'required' in \(context.documentPath) must be an array")
        }
        for requiredName in requiredNames {
          guard case .string(let name) = requiredName else { continue }
          if members[name] == nil {
            diagnostics.append("\(pointer): required — missing property '\(name)'")
            valid = false
          }
        }
      }

      if let additionalKeyword = keywords["additionalProperties"] {
        let extraNames = members.keys.filter { declaredProperties[$0] == nil }.sorted()
        switch additionalKeyword {
        case .bool(true):
          break
        case .bool(false):
          for extraName in extraNames {
            diagnostics.append(
              "\(pointer): additionalProperties — property '\(extraName)' is not allowed")
            valid = false
          }
        default:
          for extraName in extraNames {
            valid =
              try validate(
                schema: additionalKeyword,
                instance: members[extraName]!,
                context: context,
                instancePath: "\(instancePath)/\(extraName)",
                diagnostics: &diagnostics
              ) && valid
          }
        }
      }

      return valid
    }

    private func validateArrayAndScalarKeywords(
      keywords: [String: Value],
      instance: Value,
      context: Context,
      instancePath: String,
      diagnostics: inout [String]
    ) throws -> Bool {
      var valid = true
      let pointer = pointerLabel(instancePath)

      if case .array(let elements) = instance {
        if let itemsKeyword = keywords["items"] {
          for (index, element) in elements.enumerated() {
            valid =
              try validate(
                schema: itemsKeyword,
                instance: element,
                context: context,
                instancePath: "\(instancePath)/\(index)",
                diagnostics: &diagnostics
              ) && valid
          }
        }
        if case .number(let minItems)? = keywords["minItems"],
          elements.count < Int(minItems)
        {
          diagnostics.append(
            "\(pointer): minItems — expected at least \(Int(minItems)) items, got \(elements.count)")
          valid = false
        }
      }

      if case .string(let stringValue) = instance,
        case .number(let minLength)? = keywords["minLength"],
        stringValue.count < Int(minLength)
      {
        diagnostics.append(
          "\(pointer): minLength — expected at least \(Int(minLength)) characters, got \(stringValue.count)"
        )
        valid = false
      }

      if case .number(let numberValue) = instance,
        case .number(let minimum)? = keywords["minimum"],
        numberValue < minimum
      {
        diagnostics.append("\(pointer): minimum — \(numberValue) is less than \(minimum)")
        valid = false
      }

      return valid
    }

    private func validateCombinators(
      keywords: [String: Value],
      instance: Value,
      context: Context,
      instancePath: String,
      diagnostics: inout [String]
    ) throws -> Bool {
      var valid = true
      let pointer = pointerLabel(instancePath)

      if let allOfKeyword = keywords["allOf"] {
        guard case .array(let subschemas) = allOfKeyword else {
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'allOf' in \(context.documentPath) must be an array")
        }
        for subschema in subschemas {
          valid =
            try validate(
              schema: subschema,
              instance: instance,
              context: context,
              instancePath: instancePath,
              diagnostics: &diagnostics
            ) && valid
        }
      }

      if let anyOfKeyword = keywords["anyOf"] {
        guard case .array(let subschemas) = anyOfKeyword else {
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'anyOf' in \(context.documentPath) must be an array")
        }
        var branchFailureSummaries: [String] = []
        var anyBranchPassed = false
        for (index, subschema) in subschemas.enumerated() {
          var branchDiagnostics: [String] = []
          if try validate(
            schema: subschema,
            instance: instance,
            context: context,
            instancePath: instancePath,
            diagnostics: &branchDiagnostics
          ) {
            anyBranchPassed = true
            break
          }
          if let firstDiagnostic = branchDiagnostics.first {
            branchFailureSummaries.append("branch \(index): \(firstDiagnostic)")
          }
        }
        if !anyBranchPassed {
          diagnostics.append(
            "\(pointer): anyOf — no branch matched (\(subschemas.count) branches; \(branchFailureSummaries.joined(separator: "; ")))"
          )
          valid = false
        }
      }

      if let oneOfKeyword = keywords["oneOf"] {
        guard case .array(let subschemas) = oneOfKeyword else {
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "'oneOf' in \(context.documentPath) must be an array")
        }
        var matchCount = 0
        for subschema in subschemas {
          var branchDiagnostics: [String] = []
          if try validate(
            schema: subschema,
            instance: instance,
            context: context,
            instancePath: instancePath,
            diagnostics: &branchDiagnostics
          ) {
            matchCount += 1
          }
        }
        if matchCount != 1 {
          diagnostics.append(
            "\(pointer): oneOf — expected exactly 1 matching branch, got \(matchCount)")
          valid = false
        }
      }

      if let ifKeyword = keywords["if"] {
        var conditionDiagnostics: [String] = []
        let conditionPassed = try validate(
          schema: ifKeyword,
          instance: instance,
          context: context,
          instancePath: instancePath,
          diagnostics: &conditionDiagnostics
        )
        if conditionPassed {
          if let thenKeyword = keywords["then"] {
            valid =
              try validate(
                schema: thenKeyword,
                instance: instance,
                context: context,
                instancePath: instancePath,
                diagnostics: &diagnostics
              ) && valid
          }
        } else if let elseKeyword = keywords["else"] {
          valid =
            try validate(
              schema: elseKeyword,
              instance: instance,
              context: context,
              instancePath: instancePath,
              diagnostics: &diagnostics
            ) && valid
        }
      }

      return valid
    }

    private func validateRef(
      _ ref: String,
      instance: Value,
      context: Context,
      instancePath: String,
      diagnostics: inout [String]
    ) throws -> Bool {
      if ref.hasPrefix("http://") || ref.hasPrefix("https://") {
        throw JSONSchemaValidation.EngineError.unsupportedSchemaFeature(
          "remote $ref '\(ref)' in \(context.documentPath); remote schema fetching is an explicit non-goal — vendor the schema locally and use a relative-file $ref instead"
        )
      }

      let targetContext: Context
      let fragment: String
      if ref.hasPrefix("#") {
        targetContext = context
        fragment = String(ref.dropFirst())
      } else {
        let parts = ref.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let filePart = String(parts[0])
        fragment = parts.count > 1 ? String(parts[1]) : ""
        let baseDirectory = URL(fileURLWithPath: context.documentPath).deletingLastPathComponent()
        let targetURL = URL(fileURLWithPath: filePart, relativeTo: baseDirectory)
        let (document, canonicalPath) = try loadSchemaDocument(at: targetURL)
        targetContext = Context(documentPath: canonicalPath, documentRoot: document)
      }

      let resolved: Value
      if fragment.isEmpty {
        resolved = targetContext.documentRoot
      } else {
        resolved = try resolvePointer(
          fragment,
          in: targetContext.documentRoot,
          ref: ref,
          documentPath: targetContext.documentPath
        )
      }

      let frame = "\(targetContext.documentPath)#\(fragment)@\(instancePath)"
      guard activeRefFrames.insert(frame).inserted else {
        throw JSONSchemaValidation.EngineError.unsupportedSchemaFeature(
          "cyclic $ref '\(ref)' via \(targetContext.documentPath) at instance path \(pointerLabel(instancePath))"
        )
      }
      defer { activeRefFrames.remove(frame) }

      return try validate(
        schema: resolved,
        instance: instance,
        context: targetContext,
        instancePath: instancePath,
        diagnostics: &diagnostics
      )
    }

    private func resolvePointer(
      _ fragment: String,
      in root: Value,
      ref: String,
      documentPath: String
    ) throws -> Value {
      guard fragment.hasPrefix("/") else {
        throw JSONSchemaValidation.EngineError.unsupportedSchemaFeature(
          "non-pointer $ref fragment '#\(fragment)' in \(documentPath); only JSON-pointer fragments like #/$defs/name are supported"
        )
      }
      var current = root
      for rawToken in fragment.dropFirst().split(separator: "/", omittingEmptySubsequences: false) {
        let token = (String(rawToken).removingPercentEncoding ?? String(rawToken))
          .replacingOccurrences(of: "~1", with: "/")
          .replacingOccurrences(of: "~0", with: "~")
        switch current {
        case .object(let members):
          guard let next = members[token] else {
            throw JSONSchemaValidation.EngineError.schemaParseFailure(
              "unresolvable $ref '\(ref)' in \(documentPath): no member '\(token)'")
          }
          current = next
        case .array(let elements):
          guard let index = Int(token), elements.indices.contains(index) else {
            throw JSONSchemaValidation.EngineError.schemaParseFailure(
              "unresolvable $ref '\(ref)' in \(documentPath): bad array index '\(token)'")
          }
          current = elements[index]
        default:
          throw JSONSchemaValidation.EngineError.schemaParseFailure(
            "unresolvable $ref '\(ref)' in \(documentPath): cannot descend into \(current.typeName)")
        }
      }
      return current
    }

    private func matchesType(_ instance: Value, typeName: String) -> Bool {
      switch typeName {
      case "null":
        return instance == .null
      case "boolean":
        if case .bool = instance { return true }
        return false
      case "string":
        if case .string = instance { return true }
        return false
      case "number":
        if case .number = instance { return true }
        return false
      case "integer":
        if case .number(let value) = instance {
          return value.truncatingRemainder(dividingBy: 1) == 0
        }
        return false
      case "array":
        if case .array = instance { return true }
        return false
      case "object":
        if case .object = instance { return true }
        return false
      default:
        return false
      }
    }

    private func pointerLabel(_ instancePath: String) -> String {
      instancePath.isEmpty ? "/" : instancePath
    }
  }
}
