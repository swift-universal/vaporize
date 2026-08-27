import Foundation

struct VaporizeSwiftPMScratchPathPlan: Equatable, Sendable {
  let packagePath: String
  let scratchPath: String
  let packagePathLength: Int
  let predictedInlinePathLength: Int
  let predictedScratchPathLength: Int
  let safePathLimit: Int
  let warnings: [String]
}

enum VaporizeSwiftPMPathPolicy {
  static let scratchRootEnvironmentKey = "VAPORIZE_SWIFTPM_SCRATCH_ROOT"
  static let safePathLimit = 240
  static let inlineDescendantReserve = 160
  static let scratchDescendantReserve = 216

  static func windowsPlan(
    packagePath: String,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) -> VaporizeSwiftPMScratchPathPlan? {
    let normalizedPackagePath = normalizedIdentityPath(packagePath)
    let predictedInlinePathLength =
      normalizedPackagePath.count + inlineDescendantReserve
    guard predictedInlinePathLength > safePathLimit else { return nil }

    let root = windowsScratchRoot(environment: environment)
    let scratchPath = "\(root)/v/\(stablePackageKey(normalizedPackagePath))"
    let predictedScratchPathLength = scratchPath.count + scratchDescendantReserve
    let warnings =
      predictedScratchPathLength > safePathLimit
      ? [
        "Windows SwiftPM scratch path still exceeds the safe path budget: predicted \(predictedScratchPathLength), limit \(safePathLimit). Set \(scratchRootEnvironmentKey) to a shorter writable root."
      ]
      : []

    return VaporizeSwiftPMScratchPathPlan(
      packagePath: normalizedPackagePath,
      scratchPath: scratchPath,
      packagePathLength: normalizedPackagePath.count,
      predictedInlinePathLength: predictedInlinePathLength,
      predictedScratchPathLength: predictedScratchPathLength,
      safePathLimit: safePathLimit,
      warnings: warnings
    )
  }

  static func normalizedIdentityPath(_ path: String) -> String {
    path
      .replacingOccurrences(of: "\\", with: "/")
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      .lowercased()
  }

  static func windowsScratchRoot(environment: [String: String]) -> String {
    if let override = environment[scratchRootEnvironmentKey]?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !override.isEmpty
    {
      return
        override
        .replacingOccurrences(of: "\\", with: "/")
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    let systemDrive = environment["SystemDrive"]?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let drive = systemDrive?.isEmpty == false ? systemDrive! : "C:"
    return "\(drive)/b"
  }

  static func stablePackageKey(_ normalizedPackagePath: String) -> String {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for byte in normalizedPackagePath.utf8 {
      hash ^= UInt64(byte)
      hash &*= 0x100_0000_01b3
    }
    return String(format: "%016llx", hash)
  }
}
