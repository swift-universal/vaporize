import ArgumentParser
import CommonLog
import Foundation
import SwiftCLIInstaller

private let vaporizeInspectLogger: Log = {
  var logger = Log(
    system: "studio.laussat.vaporize-inspect",
    category: "inspection",
    maxExposureLevel: .trace,
    options: [.prod],
    backend: StandardErrorLogBackend()
  )
  logger.decorator = Log.Decorator.Plain()
  return logger
}()

public struct VaporizeInspectionReport: Codable, Equatable, Sendable {
  public let VaporizeInspectionReport: String
  public let capability: String
  public let platform: String
  public let state: String
  public let binPath: String
  public let persistence: String
  public let remediation: String?

  public init(_ inspection: InstalledBinPathProjectionInspection) {
    self.init(
      platform: inspection.platform,
      state: inspection.state,
      binPath: inspection.binPath,
      profilePath: inspection.profilePath
    )
  }

  public init(
    platform: InstalledBinPathProjectionPlatform,
    state: InstalledBinPathProjectionState,
    binPath: String,
    profilePath: String?
  ) {
    VaporizeInspectionReport = "v1_2608_30230"
    capability = "swiftpm-bin-user-path"
    self.platform = platform.rawValue
    self.state = state.rawValue
    self.binPath =
      platform == .windows
      ? binPath.replacingOccurrences(of: "/", with: "\\")
      : binPath
    persistence = profilePath ?? Self.persistence(for: platform)
    remediation =
      state == .missing
      ? InstalledBinPathProjectionService.remediationCommand
      : nil
  }

  public var humanDescription: String {
    let remedy = remediation.map { " remediation=\($0)" } ?? ""
    return
      "capability=\(capability) platform=\(platform) state=\(state) bin=\(binPath) persistence=\(persistence)\(remedy)"
  }

  public func jsonDescription() throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return String(decoding: try encoder.encode(self), as: UTF8.self)
  }

  private static func persistence(
    for platform: InstalledBinPathProjectionPlatform
  ) -> String {
    switch platform {
    case .windows: "HKCU\\Environment\\Path"
    case .macOS: "shell-profile"
    case .unsupported: "unsupported"
    }
  }
}

@main
public struct VaporizeInspectCLI: AsyncParsableCommand {
  public static let configuration = CommandConfiguration(
    commandName: "vaporize-inspect.cli-s@wrkstrm-core.coll",
    abstract: "Read-only Vaporize environment inspection.",
    subcommands: [Path.self]
  )

  public init() {}

  public struct Path: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
      abstract: "Inspect persistent executable search-path projections.",
      subcommands: [SwiftPMBin.self]
    )

    public init() {}

    public struct SwiftPMBin: AsyncParsableCommand {
      public static let configuration = CommandConfiguration(
        commandName: "swiftpm-bin",
        abstract: "Inspect the canonical SwiftPM user bin projection without changing it."
      )

      @Flag(name: .long, help: "Emit the typed inspection report as JSON.")
      public var json = false

      public init() {}

      public mutating func run() async throws {
        Log.globalExposureLevel = .notice
        let inspection = try await InstalledBinPathProjectionService().inspect()
        let report = VaporizeInspectionReport(inspection)
        vaporizeInspectLogger.notice(try json ? report.jsonDescription() : report.humanDescription)
      }
    }
  }
}
