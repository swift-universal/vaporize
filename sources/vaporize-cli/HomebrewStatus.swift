import Foundation
import VaporizeCLICopy_v000_000_001

/// The result of comparing the formula source, its typed release manifest, and
/// Homebrew's locally installed receipt. Each carrier answers a different
/// question; no field is inferred from another carrier.
enum HomebrewVersionCoherence: String, Codable, Equatable {
  case coherent
  case manifestMissing = "manifest-missing"
  case formulaManifestMismatch = "formula-manifest-mismatch"
  case formulaBrewMismatch = "formula-brew-mismatch"
  case installedVersionMismatch = "installed-version-mismatch"
  case notInstalled = "not-installed"
}

enum HomebrewBuildRecording: String, Codable, Equatable {
  case recorded
  case unrecorded
}

enum HomebrewArtifactCoherence: String, Codable, Equatable {
  case coherent
  case mismatch
  case unrecorded
}

struct HomebrewFormulaStatus: Codable, Equatable {
  var sourceRef: String
  var version: String
  var versionScheme: Int?
  var artifactURL: String?
  var artifactSHA256: String?
}

struct HomebrewManifestStatus: Codable, Equatable {
  var sourceRef: String
  var version: String
  var buildNumber: String?
  var sourceRevision: String?
  var sourceDirty: Bool?
  var artifactSHA256: String?
}

struct HomebrewInstalledStatus: Codable, Equatable {
  var formulaName: String?
  var stableVersion: String?
  var installedVersions: [String]
  var linkedKeg: String?
  /// Homebrew's formula revision, deliberately not a product build number.
  var formulaRevision: Int?
  var versionScheme: Int?
  var tapGitHead: String?
  var formulaSourceSHA256: String?
  var artifactSHA256: String?
}

struct HomebrewStatusReceipt: Codable, Equatable {
  var schemaVersion: String = "0.0.1"
  var kind: String = "vaporize-homebrew-status"
  var capturedAt: String
  var formula: String
  var tapRoot: String
  var evidenceBoundary: String
  var versionCoherence: HomebrewVersionCoherence
  var buildRecording: HomebrewBuildRecording
  var artifactCoherence: HomebrewArtifactCoherence
  var formulaSource: HomebrewFormulaStatus
  var manifest: HomebrewManifestStatus?
  var brew: HomebrewInstalledStatus
}

enum HomebrewStatusError: LocalizedError {
  case formulaMissing(String)
  case formulaMalformed(String)
  case brewInfoMalformed(String)

  var errorDescription: String? {
    switch self {
    case .formulaMissing(let path):
      vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeHomebrewFormulaSourceIsMissingA1, [String(describing: path)])
    case .formulaMalformed(let path):
      vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeHomebrewFormulaSourceHasNoExplicit, [String(describing: path)])
    case .brewInfoMalformed(let detail):
      vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeHomebrewDidNotReturnAFormulae, [String(describing: detail)])
    }
  }
}

/// A deterministic, offline-friendly interpreter for the three Homebrew
/// version/build carriers. `brew info --json=v2` is injected by the caller so
/// tests do not need Homebrew and all source paths remain explicit refs.
struct HomebrewStatusScanner {
  func receipt(
    formulaName: String,
    tapRoot: URL,
    brewInfoData: Data,
    capturedAt: Date = Date()
  ) throws -> HomebrewStatusReceipt {
    let normalizedTapRoot = tapRoot.standardizedFileURL
    let formulaURL = normalizedTapRoot.appendingPathComponent("Formula/\(formulaName).rb")
    let formula = try parseFormula(at: formulaURL)
    let manifestURL = normalizedTapRoot.appendingPathComponent(
      "Manifests/\(formulaName)/\(formula.version).json")
    let manifest = parseManifestIfPresent(at: manifestURL)
    let brew = try parseBrewInfo(data: brewInfoData)

    let versionCoherence = Self.versionCoherence(
      formulaVersion: formula.version,
      manifestVersion: manifest?.version,
      stableVersion: brew.stableVersion,
      installedVersions: brew.installedVersions,
      linkedKeg: brew.linkedKeg
    )
    let buildRecording: HomebrewBuildRecording = {
      guard let buildNumber = manifest?.buildNumber, !buildNumber.isEmpty else {
        return .unrecorded
      }
      return .recorded
    }()
    let artifactCoherence = Self.artifactCoherence(
      formulaSHA256: formula.artifactSHA256,
      manifestSHA256: manifest?.artifactSHA256,
      brewSHA256: brew.artifactSHA256
    )

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return HomebrewStatusReceipt(
      capturedAt: formatter.string(from: capturedAt),
      formula: formulaName,
      tapRoot: normalizedTapRoot.path,
      evidenceBoundary: "Formula source declares the public coordinate and artifact checksum; the typed tap manifest declares source provenance and product build number; brew info reports local Homebrew install state. Formula revision and version scheme are package-manager ordering metadata, never product build numbers. This report does not prove a remote release asset remains reachable or that the installed command passed runtime capability QA.",
      versionCoherence: versionCoherence,
      buildRecording: buildRecording,
      artifactCoherence: artifactCoherence,
      formulaSource: formula,
      manifest: manifest,
      brew: brew
    )
  }

  private func parseFormula(at url: URL) throws -> HomebrewFormulaStatus {
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw HomebrewStatusError.formulaMissing(url.path)
    }
    let source = try String(contentsOf: url, encoding: .utf8)
    guard let version = capture(#"(?m)^\s*version\s+\"([^\"]+)\"\s*$"#, in: source) else {
      throw HomebrewStatusError.formulaMalformed(url.path)
    }
    return HomebrewFormulaStatus(
      sourceRef: url.path,
      version: version,
      versionScheme: capture(#"(?m)^\s*version_scheme\s+([0-9]+)\s*$"#, in: source).flatMap(Int.init),
      artifactURL: capture(#"(?m)^\s*url\s+\"([^\"]+)\"\s*$"#, in: source),
      artifactSHA256: capture(#"(?m)^\s*sha256\s+\"([^\"]+)\"\s*$"#, in: source)
    )
  }

  private func parseManifestIfPresent(at url: URL) -> HomebrewManifestStatus? {
    guard let data = try? Data(contentsOf: url),
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let version = root["version"] as? String
    else { return nil }
    let build = root["build"] as? [String: Any]
    let artifact = root["artifact"] as? [String: Any]
    return HomebrewManifestStatus(
      sourceRef: url.path,
      version: version,
      buildNumber: build?["buildNumber"] as? String,
      sourceRevision: build?["sourceRevision"] as? String,
      sourceDirty: build?["sourceDirty"] as? Bool,
      artifactSHA256: artifact?["sha256"] as? String
    )
  }

  private func parseBrewInfo(data: Data) throws -> HomebrewInstalledStatus {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let formulae = root["formulae"] as? [[String: Any]],
      let formula = formulae.first
    else {
      throw HomebrewStatusError.brewInfoMalformed("expected top-level formulae[0]")
    }
    let versions = formula["versions"] as? [String: Any]
    let installed = formula["installed"] as? [[String: Any]] ?? []
    let urls = formula["urls"] as? [String: Any]
    let stable = urls?["stable"] as? [String: Any]
    let formulaSourceChecksum = formula["ruby_source_checksum"] as? [String: Any]
    return HomebrewInstalledStatus(
      formulaName: formula["full_name"] as? String ?? formula["name"] as? String,
      stableVersion: versions?["stable"] as? String,
      installedVersions: installed.compactMap { $0["version"] as? String }.sorted(),
      linkedKeg: formula["linked_keg"] as? String,
      formulaRevision: formula["revision"] as? Int,
      versionScheme: formula["version_scheme"] as? Int,
      tapGitHead: formula["tap_git_head"] as? String,
      formulaSourceSHA256: formulaSourceChecksum?["sha256"] as? String,
      artifactSHA256: stable?["checksum"] as? String
    )
  }

  private func capture(_ pattern: String, in source: String) -> String? {
    guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(source.startIndex..., in: source)
    guard let match = expression.firstMatch(in: source, range: range), match.numberOfRanges > 1,
      let valueRange = Range(match.range(at: 1), in: source)
    else { return nil }
    return String(source[valueRange])
  }

  private static func versionCoherence(
    formulaVersion: String,
    manifestVersion: String?,
    stableVersion: String?,
    installedVersions: [String],
    linkedKeg: String?
  ) -> HomebrewVersionCoherence {
    guard let manifestVersion else { return .manifestMissing }
    guard manifestVersion == formulaVersion else { return .formulaManifestMismatch }
    guard stableVersion == formulaVersion else { return .formulaBrewMismatch }
    guard !installedVersions.isEmpty else { return .notInstalled }
    guard installedVersions.contains(formulaVersion), linkedKeg == formulaVersion else {
      return .installedVersionMismatch
    }
    return .coherent
  }

  private static func artifactCoherence(
    formulaSHA256: String?,
    manifestSHA256: String?,
    brewSHA256: String?
  ) -> HomebrewArtifactCoherence {
    let values = [formulaSHA256, manifestSHA256, brewSHA256].compactMap { $0 }
    guard values.count == 3 else { return .unrecorded }
    return Set(values).count == 1 ? .coherent : .mismatch
  }
}

enum HomebrewStatusRenderer {
  static func renderJSON(_ receipt: HomebrewStatusReceipt) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(receipt)
  }

  static func renderText(_ receipt: HomebrewStatusReceipt) -> String {
    let formulaVersionScheme = receipt.formulaSource.versionScheme.map(String.init) ?? "unrecorded"
    let formulaSHA256 = receipt.formulaSource.artifactSHA256 ?? "unrecorded"
    let stableVersion = receipt.brew.stableVersion ?? "unrecorded"
    let installedVersions = receipt.brew.installedVersions.isEmpty
      ? "none"
      : receipt.brew.installedVersions.joined(separator: ",")
    let linkedKeg = receipt.brew.linkedKeg ?? "unrecorded"
    let formulaRevision = receipt.brew.formulaRevision.map(String.init) ?? "unrecorded"
    var lines = [
      "homebrew-status: formula=\(receipt.formula) version=\(receipt.versionCoherence.rawValue) build=\(receipt.buildRecording.rawValue) artifact=\(receipt.artifactCoherence.rawValue)",
      "formula: version=\(receipt.formulaSource.version) version-scheme=\(formulaVersionScheme) sha256=\(formulaSHA256) ref=\(receipt.formulaSource.sourceRef)",
    ]
    if let manifest = receipt.manifest {
      let buildNumber = manifest.buildNumber ?? "unrecorded"
      let sourceRevision = manifest.sourceRevision ?? "unrecorded"
      let sourceDirty = manifest.sourceDirty.map { $0 ? "true" : "false" } ?? "unrecorded"
      lines.append(
        "manifest: version=\(manifest.version) build=\(buildNumber) source-revision=\(sourceRevision) dirty=\(sourceDirty) ref=\(manifest.sourceRef)"
      )
    } else {
      lines.append("manifest: unrecorded")
    }
    lines.append(
      "brew: stable=\(stableVersion) installed=\(installedVersions) linked-keg=\(linkedKeg) formula-revision=\(formulaRevision)"
    )
    lines.append("boundary: \(receipt.evidenceBoundary)")
    return lines.joined(separator: "\n")
  }
}
