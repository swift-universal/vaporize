import ArgumentParser
import SwiftCLIInstaller
import Testing
@testable import VaporizeInspectCLI

@Suite("Vaporize inspect CLI")
struct VaporizeInspectCLITests {
  @Test("The SwiftPM bin inspection route is independently parseable")
  func parsesSwiftPMBinInspection() throws {
    let command = try VaporizeInspectCLI.parseAsRoot(["path", "swiftpm-bin", "--json"])
    let inspection = try #require(command as? VaporizeInspectCLI.Path.SwiftPMBin)

    #expect(inspection.json)
  }

  @Test("Windows reports its persistent user PATH surface and remediation")
  func describesWindowsPersistence() throws {
    let report = VaporizeInspectionReport(
      platform: .windows,
      state: .missing,
      binPath: "C:\\Users\\operator\\.swiftpm\\bin",
      profilePath: nil
    )

    #expect(report.platform == "windows")
    #expect(report.binPath == "C:\\Users\\operator\\.swiftpm\\bin")
    #expect(report.persistence == "HKCU\\Environment\\Path")
    #expect(report.remediation == InstalledBinPathProjectionService.remediationCommand)
    #expect(try report.jsonDescription().contains("\"VaporizeInspectionReport\""))
  }

  @Test("macOS reports the selected shell profile")
  func describesMacOSPersistence() {
    let report = VaporizeInspectionReport(
      platform: .macOS,
      state: .present,
      binPath: "/Users/operator/.swiftpm/bin",
      profilePath: "/Users/operator/.zprofile"
    )

    #expect(report.persistence == "/Users/operator/.zprofile")
    #expect(report.remediation == nil)
  }
}
