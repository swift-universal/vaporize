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
  case xcode

  var alternate: Self {
    switch self {
    case .swift: .xcode
    case .xcode: .swift
    }
  }
}

enum VaporizeCoreCommandPlatform: Equatable, Sendable {
  case macOS
  case nonMacOS

  static var current: Self {
    #if os(macOS)
      .macOS
    #else
      .nonMacOS
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
    case .xcode: "xcrun-xcode-select"
    }
  }

  var alternateCommandPrefix: String? {
    guard !commandCollapsed else { return nil }
    return "vaporize.cli@wrkstrm-core.clia.sh \(operation.rawValue) \(executionAuthority.alternate.rawValue)"
  }

  static func resolve(
    operation: VaporizeCoreOperation,
    arguments: [String],
    platform: VaporizeCoreCommandPlatform = .current
  ) throws -> Self {
    switch platform {
    case .macOS:
      guard let authorityArgument = arguments.first,
        let authority = VaporizeCoreExecutionAuthority(rawValue: authorityArgument)
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

    case .nonMacOS:
      if let first = arguments.first,
        VaporizeCoreExecutionAuthority(rawValue: first) != nil
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
    guard !commandCollapsed else { return nil }
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
    sibling[authorityIndex] = executionAuthority.alternate.rawValue
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
