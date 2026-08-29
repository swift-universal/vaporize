import Foundation

struct VaporizeWindowsUserPathPlan: Equatable, Sendable {
  let swiftPMBinPath: String
  let updatedUserPath: String
  let changed: Bool
}

enum VaporizeWindowsUserPathPolicy {
  static let remediationCommand =
    "vaporize.cli@wrkstrm-core.clia.sh path add-swiftpm-bin"

  static func swiftPMBinPath(homeDirectory: URL) -> String {
    homeDirectory
      .appendingPathComponent(".swiftpm", isDirectory: true)
      .appendingPathComponent("bin", isDirectory: true)
      .path
  }

  static func plan(userPath: String?, homeDirectory: URL) -> VaporizeWindowsUserPathPlan {
    let target = swiftPMBinPath(homeDirectory: homeDirectory)
    let entries = split(userPath)
    let targetKey = normalized(target, homeDirectory: homeDirectory)
    let alreadyPresent = entries.contains {
      normalized($0, homeDirectory: homeDirectory) == targetKey
    }
    guard !alreadyPresent else {
      return VaporizeWindowsUserPathPlan(
        swiftPMBinPath: target,
        updatedUserPath: entries.joined(separator: ";"),
        changed: false
      )
    }

    return VaporizeWindowsUserPathPlan(
      swiftPMBinPath: target,
      updatedUserPath: (entries + [target]).joined(separator: ";"),
      changed: true
    )
  }

  static func containsSwiftPMBin(path: String?, homeDirectory: URL) -> Bool {
    !plan(userPath: path, homeDirectory: homeDirectory).changed
  }

  private static func split(_ path: String?) -> [String] {
    (path ?? "")
      .split(separator: ";", omittingEmptySubsequences: true)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  private static func normalized(_ path: String, homeDirectory: URL) -> String {
    let home = homeDirectory.path.replacingOccurrences(of: "\\", with: "/")
    return
      path
      .replacingOccurrences(of: "%USERPROFILE%", with: home, options: .caseInsensitive)
      .replacingOccurrences(of: "\\", with: "/")
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      .lowercased()
  }
}

#if os(Windows)
  enum VaporizeWindowsUserPathPowerShell {
    static let script = #"""
      $ErrorActionPreference = 'Stop'
      $target = [Environment]::GetEnvironmentVariable('VAPORIZE_SWIFTPM_BIN', 'Process')
      $operation = [Environment]::GetEnvironmentVariable('VAPORIZE_PATH_OPERATION', 'Process')
      if ([string]::IsNullOrWhiteSpace($target)) {
        throw 'VAPORIZE_SWIFTPM_BIN is missing.'
      }
      $normalize = {
        param([string]$value)
        if ([string]::IsNullOrWhiteSpace($value)) { return '' }
        $expanded = [Environment]::ExpandEnvironmentVariables($value.Trim())
        return $expanded.Replace('/', '\').TrimEnd('\').ToLowerInvariant()
      }
      $current = [Environment]::GetEnvironmentVariable('Path', 'User')
      $entries = @($current -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
      $targetKey = & $normalize $target
      $present = @($entries | Where-Object { (& $normalize $_) -eq $targetKey }).Count -gt 0
      if ($operation -eq 'inspect') {
        if ($present) { 'present' } else { 'missing' }
        exit 0
      }
      if ($operation -ne 'add') { throw "Unsupported VAPORIZE_PATH_OPERATION: $operation" }
      if ($present) {
        'already-present'
        exit 0
      }
      $updated = @($entries + $target) -join ';'
      [Environment]::SetEnvironmentVariable('Path', $updated, 'User')
      $verified = [Environment]::GetEnvironmentVariable('Path', 'User')
      $verifiedEntries = @($verified -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
      $verifiedPresent = @($verifiedEntries | Where-Object { (& $normalize $_) -eq $targetKey }).Count -gt 0
      if (-not $verifiedPresent) { throw 'The user PATH write did not verify.' }
      'added'
      """#
  }
#endif
