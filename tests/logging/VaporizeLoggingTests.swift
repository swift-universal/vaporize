import CommonLog
import Testing

@testable import VaporizeCLI

@Suite(.serialized)
struct VaporizeLoggingTests {
  @Test("All supported logging levels configure CommonLog exposure")
  func configuredLevels() {
    for level in VaporizeLogLevel.allCases {
      VaporizeLogging.configure(level: level)
      switch level {
      case .trace: #expect(Log.globalExposureLevel == .trace)
      case .debug: #expect(Log.globalExposureLevel == .debug)
      case .info: #expect(Log.globalExposureLevel == .info)
      case .notice: #expect(Log.globalExposureLevel == .notice)
      case .warning: #expect(Log.globalExposureLevel == .warning)
      case .error: #expect(Log.globalExposureLevel == .error)
      case .critical: #expect(Log.globalExposureLevel == .critical)
      }
    }
  }

  @Test("Logging level spellings remain stable for the CLI")
  func stableSpellings() {
    #expect(
      VaporizeLogLevel.allCases.map(\.rawValue) == [
        "trace",
        "debug",
        "info",
        "notice",
        "warning",
        "error",
        "critical",
      ])
  }

  @Test("Sensitive option and environment values are redacted")
  func redaction() {
    let input =
      "run --token secret-value --api-key=another-secret SERVICE_PASSWORD=hunter2 safe=value"
    let output = VaporizeLogging.redacted(input)

    #expect(
      output == "run --token <redacted> --api-key=<redacted> SERVICE_PASSWORD=<redacted> safe=value"
    )
    #expect(!output.contains("secret-value"))
    #expect(!output.contains("another-secret"))
    #expect(!output.contains("hunter2"))
  }
}
