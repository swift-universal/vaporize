import ArgumentParser
import Foundation
import VaporizeCLICopy_v000_000_001

enum VaporizeCoreOperation: String, CaseIterable, Codable, Equatable, Sendable {
  case install
  case build
  case test
  case run
}

enum VaporizeCoreExecutionAuthority: String, Codable, Equatable, Sendable {
  case swift

  #if os(macOS)
    case xcode
  #endif

  #if os(Windows)
    case swiftWin = "swift-win"
    case wcode
  #endif

  var alternate: Self? {
    switch self {
    case .swift:
      #if os(macOS)
        .xcode
      #else
        nil
      #endif
    #if os(macOS)
      case .xcode: .swift
    #endif
    #if os(Windows)
      // WCode owns application lifecycle work, while swift-win owns raw SwiftPM
      // products. They are deliberately not retry siblings: changing between
      // them changes the artifact contract rather than just the toolchain.
      case .swiftWin, .wcode: nil
    #endif
    }
  }
}

enum VaporizeCoreCommandPlatform: Equatable, Sendable {
  case macOS
  case windows
  case other

  static var current: Self {
    #if os(macOS)
      .macOS
    #elseif os(Windows)
      .windows
    #else
      .other
    #endif
  }
}

struct VaporizeCoreExecutionPlan: Codable, Equatable, Sendable {
  var operation: VaporizeCoreOperation
  var executionAuthority: VaporizeCoreExecutionAuthority
  var forwardedArguments: [String]
  var commandCollapsed: Bool

  var toolchainResolver: String {
    switch executionAuthority {
    case .swift: "default-swift"
    #if os(macOS)
      case .xcode: "xcrun-xcode-select"
    #endif
    #if os(Windows)
      case .swiftWin: "windows-swiftpm"
      case .wcode: "wcode-app-lifecycle"
    #endif
    }
  }

  var alternateCommandPrefix: String? {
    guard !commandCollapsed, let alternate = executionAuthority.alternate else { return nil }
    return "vaporize.cli@wrkstrm-core.clia.sh \(operation.rawValue) \(alternate.rawValue)"
  }

  static func resolve(
    operation: VaporizeCoreOperation,
    arguments: [String],
    platform: VaporizeCoreCommandPlatform = .current
  ) throws -> Self {
    switch platform {
    case .macOS:
      #if os(macOS)
      guard let authorityArgument = arguments.first,
        let authority = VaporizeCoreExecutionAuthority(rawValue: authorityArgument),
        authority == .swift || authority == .xcode
      else {
        throw ValidationError(
          vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeA1RequiresAnExecutionAuthority, ["\(operation.rawValue)", "\(operation.rawValue)", "\(operation.rawValue)"])
        )
      }
      return Self(
        operation: operation,
        executionAuthority: authority,
        forwardedArguments: Array(arguments.dropFirst()),
        commandCollapsed: false
      )
      #else
        throw ValidationError("The Xcode execution authority is available only on macOS.")
      #endif

    case .windows:
      #if os(Windows)
      guard let authorityArgument = arguments.first,
        let authority = VaporizeCoreExecutionAuthority(rawValue: authorityArgument),
        authority == .swiftWin || authority == .wcode
      else {
        throw ValidationError(
          "Windows core execution commands require the swift-win or wcode authority."
        )
      }
      return Self(
        operation: operation,
        executionAuthority: authority,
        forwardedArguments: Array(arguments.dropFirst()),
        commandCollapsed: false
      )
      #else
        throw ValidationError("The WCode execution authority is available only on Windows.")
      #endif

    case .other:
      if let first = arguments.first,
        ["swift", "swift-win", "xcode", "wcode"].contains(first)
      {
        throw ValidationError(
          vaporizeCopyFill(VaporizeCLICopy_v000_000_001.CLI.vaporizeVaporizeA1IsAlreadyTheCollapsed, ["\(operation.rawValue)", "\(first)"])
        )
      }
      return Self(
        operation: operation,
        executionAuthority: .swift,
        forwardedArguments: arguments,
        commandCollapsed: true
      )
    }
  }

  func alternateCommand(
    invocation: [String],
    canonicalExecutableName: String = "vaporize.cli@wrkstrm-core.clia.sh"
  ) -> String? {
    guard !commandCollapsed, let alternate = executionAuthority.alternate else { return nil }
    guard let operationIndex = invocation.firstIndex(of: operation.rawValue) else {
      return alternateCommandPrefix
    }
    let authorityIndex = invocation.index(after: operationIndex)
    guard invocation.indices.contains(authorityIndex),
      invocation[authorityIndex] == executionAuthority.rawValue
    else {
      return alternateCommandPrefix
    }

    var sibling = invocation
    sibling[authorityIndex] = alternate.rawValue
    if !sibling.isEmpty {
      sibling[0] = canonicalExecutableName
    } else {
      sibling.insert(canonicalExecutableName, at: 0)
    }
    return sibling.map(Self.shellEscaped).joined(separator: " ")
  }

  private static func shellEscaped(_ argument: String) -> String {
    guard !argument.isEmpty else { return "''" }
    let safe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._/:=@+"))
    if argument.unicodeScalars.allSatisfy({ safe.contains($0) }) {
      return argument
    }
    return "'\(argument.replacingOccurrences(of: "'", with: "'\\''"))'"
  }
}
