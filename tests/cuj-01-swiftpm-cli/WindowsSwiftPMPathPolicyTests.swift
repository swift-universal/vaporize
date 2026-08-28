import Foundation
import Testing

@testable import VaporizeCLI

@Suite("CUJ-01 Windows SwiftPM path survival")
struct WindowsSwiftPMPathPolicyTests {
  @Test("Deep Windows packages receive deterministic short scratch headroom")
  func deepPackageReceivesShortScratchPath() throws {
    let packagePath = "C:/" + String(repeating: "deep-package/", count: 16)
    let plan = try #require(
      VaporizeSwiftPMPathPolicy.windowsPlan(
        packagePath: packagePath,
        environment: ["SystemDrive": "C:"]
      )
    )

    #expect(plan.scratchPath.hasPrefix("C:/b/v/"))
    #expect(plan.scratchPath.count < packagePath.count)
    #expect(plan.predictedInlinePathLength > plan.safePathLimit)
    #expect(plan.predictedScratchPathLength <= plan.safePathLimit)
    #expect(plan.warnings.isEmpty)
  }

  @Test("Equivalent Windows path spellings share one package key")
  func equivalentPathSpellingsShareKey() {
    let first = VaporizeSwiftPMPathPolicy.stablePackageKey(
      VaporizeSwiftPMPathPolicy.normalizedIdentityPath("C:\\Work\\Package\\")
    )
    let second = VaporizeSwiftPMPathPolicy.stablePackageKey(
      VaporizeSwiftPMPathPolicy.normalizedIdentityPath("c:/work/package")
    )

    #expect(first == second)
    #expect(first.count == 16)
  }

  @Test("Operator scratch root override remains authoritative and warns instead of blocking")
  func overrideRemainsAuthoritative() throws {
    let packagePath = "C:/" + String(repeating: "deep-package/", count: 16)
    let short = try #require(
      VaporizeSwiftPMPathPolicy.windowsPlan(
        packagePath: packagePath,
        environment: [
          VaporizeSwiftPMPathPolicy.scratchRootEnvironmentKey: "D:\\s"
        ]
      )
    )
    #expect(short.scratchPath.hasPrefix("D:/s/v/"))
    #expect(short.warnings.isEmpty)

    let long = try #require(
      VaporizeSwiftPMPathPolicy.windowsPlan(
        packagePath: packagePath,
        environment: [
          VaporizeSwiftPMPathPolicy.scratchRootEnvironmentKey:
            "D:/" + String(repeating: "long-root/", count: 12)
        ]
      )
    )
    #expect(long.warnings.count == 1)
    #expect(!long.scratchPath.isEmpty)
  }

  @Test("Short packages preserve the existing inline SwiftPM workspace")
  func shortPackagePreservesInlineWorkspace() {
    #expect(
      VaporizeSwiftPMPathPolicy.windowsPlan(
        packagePath: "C:/work/package",
        environment: ["SystemDrive": "C:"]
      ) == nil
    )
  }

  #if os(Windows)
    @Test("Deep Windows build command adopts the planned scratch path")
    // bead: [[bug-vaporize-windows-source-built-cli-exe-2026-08-27]]
    func deepBuildCommandAdoptsScratchPath() throws {
      let packagePath = "C:/" + String(repeating: "deep-package/", count: 16)
      let command = try VaporizeCLI.parse([
        "build", "swift-win",
        "--artifact", "cli",
        "--package-path", packagePath,
        "--product", "tool.cli@org.clia.sh",
        "--configuration", "debug",
      ])
      let arguments = try command.swiftBuildArguments()
      let plan = try #require(
        VaporizeSwiftPMPathPolicy.windowsPlan(packagePath: packagePath)
      )

      #expect(arguments.prefix(3) == ["build", "--scratch-path", plan.scratchPath])
      #expect(command.usesIsolatedSwiftPMWorkspace)
      #expect(
        command.sourceBuiltCLIExecutablePath(product: "tool.cli@org.clia.sh")
          == "\(plan.scratchPath)/out/Products/Debug/tool.cli@org.clia.sh.exe"
      )
    }

    @Test("Explicit scratch override wins for a deep Windows package")
    func explicitScratchOverrideWins() throws {
      let packagePath = "C:/" + String(repeating: "deep-package/", count: 16)
      let command = try VaporizeCLI.parse([
        "build", "swift-win",
        "--artifact", "cli",
        "--package-path", packagePath,
        "--product", "tool.cli@org.clia.sh",
        "--configuration", "debug",
        "--scratch-path", "D:/operator-owned",
      ])

      #expect(
        try command.swiftBuildArguments().prefix(3)
          == ["build", "--scratch-path", "D:/operator-owned"]
      )
    }
  #endif
}
