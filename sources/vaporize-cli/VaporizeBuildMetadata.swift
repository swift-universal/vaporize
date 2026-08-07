import Foundation
import SwiftCLIInstaller

/// The build identity shown by a running Vaporize executable. An installed CLI
/// sidecar is authoritative for an installed copy; environment values remain
/// useful while inspecting an uninstalled build product.
struct VaporizeRuntimeBuildMetadata: Equatable {
  enum Authority: String, Equatable {
    case installedSidecar = "installed-sidecar"
    case environment
    case localDefault = "local-default"
  }

  var buildNumber: String
  var buildSHA: String?
  var buildDate: String?
  var sidecarVersion: String?
  var authority: Authority
}

enum VaporizeBuildMetadataResolver {
  static func resolve(
    fallbackBuildNumber: String,
    fallbackBuildSHA: String?,
    fallbackBuildDate: String?,
    executablePath: String? = VaporizeInvocation.executablePath()
  ) -> VaporizeRuntimeBuildMetadata {
    guard let executablePath else {
      return fallback(
        buildNumber: fallbackBuildNumber,
        buildSHA: fallbackBuildSHA,
        buildDate: fallbackBuildDate
      )
    }

    let executableURL = URL(fileURLWithPath: executablePath).standardizedFileURL
    let product = executableURL.lastPathComponent
    let binDirectory = executableURL.deletingLastPathComponent()
    let readSidecar: InstalledProductSidecar?
    do {
      readSidecar = try InstalledProductSidecar.readIfPresent(
        product: product,
        binDirectory: binDirectory
      )
    } catch {
      return fallback(
        buildNumber: fallbackBuildNumber,
        buildSHA: fallbackBuildSHA,
        buildDate: fallbackBuildDate
      )
    }
    guard let sidecar = readSidecar else {
      return fallback(
        buildNumber: fallbackBuildNumber,
        buildSHA: fallbackBuildSHA,
        buildDate: fallbackBuildDate
      )
    }

    let buildNumber = sidecar.payload["CFBundleVersion"]
    guard let buildNumber, !buildNumber.isEmpty else {
      return fallback(
        buildNumber: fallbackBuildNumber,
        buildSHA: fallbackBuildSHA,
        buildDate: fallbackBuildDate
      )
    }

    return VaporizeRuntimeBuildMetadata(
      buildNumber: buildNumber,
      buildSHA: sidecar.payload["VaporizeProductBuildSHA"] ?? fallbackBuildSHA,
      buildDate: sidecar.payload["VaporizeProductBuildDate"] ?? fallbackBuildDate,
      sidecarVersion: sidecar.shortVersionString,
      authority: .installedSidecar
    )
  }

  private static func fallback(
    buildNumber: String,
    buildSHA: String?,
    buildDate: String?
  ) -> VaporizeRuntimeBuildMetadata {
    VaporizeRuntimeBuildMetadata(
      buildNumber: buildNumber,
      buildSHA: buildSHA,
      buildDate: buildDate,
      sidecarVersion: nil,
      authority: buildNumber == "local" ? .localDefault : .environment
    )
  }
}
