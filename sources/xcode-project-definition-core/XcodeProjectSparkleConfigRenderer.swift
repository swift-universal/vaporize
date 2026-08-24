import Foundation

/// Typed failures for Sparkle self-update config generation. Every case names
/// exactly which value is missing so a tool never ships with a placeholder or
/// empty Sparkle identity (see [[tooling-silent-fallback-to-wrong-state-not-error-loud]]).
public enum XcodeProjectSparkleConfigRendererError: Error, CustomStringConvertible, Equatable {
  case targetNotFound(targetName: String, availableTargets: [String])
  case missingReleaseIdentity(targetName: String)
  case missingSparkleFeedURL(targetName: String)
  case invalidSparkleFeedURL(targetName: String, sparkleFeedURL: String)
  case missingSparklePublicEDKey(targetName: String)
  case missingShortVersion(targetName: String)

  public var description: String {
    switch self {
    case .targetNotFound(let targetName, let availableTargets):
      return
        "generate-sparkle-config: target \(targetName) not found in spec; available targets: \(availableTargets.joined(separator: ", "))"
    case .missingReleaseIdentity(let targetName):
      return
        "generate-sparkle-config: target \(targetName) has no releaseIdentity; add one with sparkleFeedURL, sparklePublicEDKey, and shortVersion."
    case .missingSparkleFeedURL(let targetName):
      return
        "generate-sparkle-config: target \(targetName) releaseIdentity is missing sparkleFeedURL."
    case .invalidSparkleFeedURL(let targetName, let sparkleFeedURL):
      return
        "generate-sparkle-config: target \(targetName) releaseIdentity sparkleFeedURL is not a valid absolute URL: \(sparkleFeedURL)"
    case .missingSparklePublicEDKey(let targetName):
      return
        "generate-sparkle-config: target \(targetName) releaseIdentity is missing sparklePublicEDKey."
    case .missingShortVersion(let targetName):
      return
        "generate-sparkle-config: target \(targetName) releaseIdentity is missing shortVersion (the compiled-in currentVersion)."
    }
  }
}

/// Renders the compiled-in `SparkleConfig.swift` for a CLI tool target from an
/// evaluated `XcodeProjectDefinition`. The target's `releaseIdentity` (sparkleFeedURL
/// + sparklePublicEDKey + shortVersion) is the single typed source for the
/// tool's self-update identity; the generated file compiles against the
/// swift-universal `SwiftCLIUpdater` library's `SparkleConfig` initializer.
///
/// Boundary: source-text generation only. Wiring the generated file into the
/// install/run lane and the self-update verb is a separate component (Lane C).
public enum XcodeProjectSparkleConfigRenderer {
  public static func renderData(
    spec: XcodeProjectDefinition,
    targetName: String,
    sourcePath: String? = nil
  ) throws -> Data {
    Data(try render(spec: spec, targetName: targetName, sourcePath: sourcePath).utf8)
  }

  public static func render(
    spec: XcodeProjectDefinition,
    targetName: String,
    sourcePath: String? = nil
  ) throws -> String {
    guard let target = spec.targets[targetName] else {
      throw XcodeProjectSparkleConfigRendererError.targetNotFound(
        targetName: targetName,
        availableTargets: spec.targets.keys.sorted()
      )
    }
    guard let identity = target.releaseIdentity else {
      throw XcodeProjectSparkleConfigRendererError.missingReleaseIdentity(targetName: targetName)
    }
    guard let sparkleFeedURL = identity.sparkleFeedURL, !sparkleFeedURL.isEmpty else {
      throw XcodeProjectSparkleConfigRendererError.missingSparkleFeedURL(targetName: targetName)
    }
    guard
      let feedURL = URL(string: sparkleFeedURL),
      let scheme = feedURL.scheme, !scheme.isEmpty,
      let host = feedURL.host, !host.isEmpty
    else {
      throw XcodeProjectSparkleConfigRendererError.invalidSparkleFeedURL(
        targetName: targetName,
        sparkleFeedURL: sparkleFeedURL
      )
    }
    guard let sparklePublicEDKey = identity.sparklePublicEDKey, !sparklePublicEDKey.isEmpty else {
      throw XcodeProjectSparkleConfigRendererError.missingSparklePublicEDKey(targetName: targetName)
    }
    guard let shortVersion = identity.shortVersion, !shortVersion.isEmpty else {
      throw XcodeProjectSparkleConfigRendererError.missingShortVersion(targetName: targetName)
    }

    let productName = target.settings?.base?["PRODUCT_NAME"]?.stringValue ?? targetName

    var lines: [String] = [
      "// SparkleConfig.swift",
      "// GENERATED FROM PKL by Vaporize (generate-sparkle-config) — DO NOT EDIT.",
    ]
    if let sourcePath, !sourcePath.isEmpty {
      lines.append("// Source manifest: \(sourcePath)")
    }
    lines.append("// Target: \(targetName)")
    lines.append(
      "// The project.pkl releaseIdentity is the single typed source for this"
    )
    lines.append("// tool's self-update identity. Regenerate; never hand-edit.")
    lines.append("")
    lines.append("import Foundation")
    lines.append("import SwiftCLIUpdater")
    lines.append("")
    lines.append("extension SparkleConfig {")
    lines.append("  /// Compiled-in Sparkle self-update identity for \(productName).")
    lines.append("  public static let generated = SparkleConfig(")
    lines.append("    productName: \(swiftStringLiteral(productName)),")
    lines.append("    // Validated as an absolute URL at generation time.")
    lines.append("    feedURL: URL(string: \(swiftStringLiteral(feedURL.absoluteString)))!,")
    lines.append("    publicEDKeyBase64: \(swiftStringLiteral(sparklePublicEDKey)),")
    lines.append("    currentVersion: \(swiftStringLiteral(shortVersion))")
    lines.append("  )")
    lines.append("}")
    lines.append("")
    return lines.joined(separator: "\n")
  }

  private static func swiftStringLiteral(_ value: String) -> String {
    var rendered = "\""
    for scalar in value.unicodeScalars {
      switch scalar {
      case "\\":
        rendered += "\\\\"
      case "\"":
        rendered += "\\\""
      case "\n":
        rendered += "\\n"
      case "\r":
        rendered += "\\r"
      case "\t":
        rendered += "\\t"
      default:
        rendered.unicodeScalars.append(scalar)
      }
    }
    rendered += "\""
    return rendered
  }
}
