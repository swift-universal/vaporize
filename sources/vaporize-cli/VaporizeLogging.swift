import ArgumentParser
import CommonLog

enum VaporizeLogLevel: String, CaseIterable, ExpressibleByArgument, Sendable {
  case trace
  case debug
  case info
  case notice
  case warning
  case error
  case critical

  func configureCommonLog() {
    switch self {
    case .trace:
      Log.globalExposureLevel = .trace
    case .debug:
      Log.globalExposureLevel = .debug
    case .info:
      Log.globalExposureLevel = .info
    case .notice:
      Log.globalExposureLevel = .notice
    case .warning:
      Log.globalExposureLevel = .warning
    case .error:
      Log.globalExposureLevel = .error
    case .critical:
      Log.globalExposureLevel = .critical
    }
  }
}

enum VaporizeLogging {
  static let command = makeLogger(category: "command")
  static let coreExecution = makeLogger(category: "core-execution")
  static let depot = makeLogger(category: "third-party-depot")

  static func configure(level: VaporizeLogLevel) {
    level.configureCommonLog()
  }

  static func redacted(_ value: String) -> String {
    var components = value.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
    var redactNext = false

    for index in components.indices {
      if redactNext {
        components[index] = "<redacted>"
        redactNext = false
        continue
      }

      let component = components[index]
      let lowercased = component.lowercased()
      if sensitiveKeys.contains(lowercased) {
        redactNext = true
        continue
      }

      guard let separator = component.firstIndex(of: "=") else { continue }
      let key = String(component[..<separator]).lowercased()
      if sensitiveKeys.contains(key) || sensitiveEnvironmentKey(key) {
        components[index] = "\(component[..<separator])=<redacted>"
      }
    }

    return components.joined(separator: " ")
  }

  private static let sensitiveKeys: Set<String> = [
    "--api-key",
    "--authorization",
    "--password",
    "--secret",
    "--token",
  ]

  private static func sensitiveEnvironmentKey(_ key: String) -> Bool {
    key.hasSuffix("_api_key") || key.hasSuffix("_authorization")
      || key.hasSuffix("_password") || key.hasSuffix("_secret")
      || key.hasSuffix("_token")
  }

  private static func makeLogger(category: String) -> Log {
    var logger = Log(
      system: "studio.laussat.vaporize",
      category: category,
      maxExposureLevel: .trace,
      options: [.prod],
      backend: StandardErrorLogBackend()
    )
    logger.decorator = Log.Decorator.Plain()
    return logger
  }
}
