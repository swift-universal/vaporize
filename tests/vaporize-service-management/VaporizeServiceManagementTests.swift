import Foundation
import Testing
import VaporizeProjectModel
import VaporizeServiceManagement

@Suite("Vaporize managed service registration")
struct VaporizeServiceManagementTests {
  private let service = VaporizeService(
    executable: "%USERPROFILE%\\.swiftpm\\bin\\takumi-fused.exe",
    arguments: ["serve", "--host", "127.0.0.1", "--port", "8003"],
    workingDirectory: "%USERPROFILE%\\models\\takumi",
    environment: [
      "PATH": "%USERPROFILE%\\cuda;%Path%",
      "TAKUMI_MODEL": "qwen",
    ],
    restartPolicy: .onFailure,
    healthCheck: .init(kind: .http, url: "http://127.0.0.1:8003/v1/models")
  )

  @Test("Runtime platform selection is injectable and contains no compile-time branch")
  func detectsPlatforms() {
    #expect(
      VaporizeServiceHostPlatform.detect(
        environment: ["OS": "Windows_NT"],
        fileExists: { _ in false }
      ) == .windows)
    #expect(
      VaporizeServiceHostPlatform.detect(
        environment: [:],
        fileExists: { $0 == "/System/Library/CoreServices" }
      ) == .macos)
    #expect(
      VaporizeServiceHostPlatform.detect(
        environment: [:],
        fileExists: { _ in false }
      ) == .linux)
  }

  @Test("Windows install plan registers a current-user logon task and launcher")
  func rendersWindowsTask() throws {
    let context = VaporizeServiceRuntimeContext(
      platform: .windows,
      homeDirectory: "C:\\Users\\operator",
      localApplicationDataDirectory: "C:\\Users\\operator\\AppData\\Local",
      accountName: "WORKSTATION\\operator"
    )
    let plan = try WindowsTaskSchedulerServiceAdapter().plan(
      action: .install,
      serviceID: "takumi-fused",
      service: service,
      context: context,
      environment: [
        "Path": "C:\\Windows\\System32",
        "USERPROFILE": "C:\\Users\\operator",
      ]
    )

    #expect(plan.backend == "windows-task-scheduler")
    #expect(plan.steps.count == 6)
    guard case .write(let launcherPath, let launcherData) = plan.steps[3],
      case .write(let taskPath, let taskData) = plan.steps[4],
      case .command(let command) = plan.steps[5]
    else {
      Issue.record("Windows installation must write a launcher and task XML before registration")
      return
    }
    let launcher = String(decoding: launcherData, as: UTF8.self)
    let task = try #require(String(data: taskData, encoding: .utf16LittleEndian))
    #expect(launcherPath.hasSuffix("wrkstrm/services/takumi-fused/launch.ps1"))
    #expect(taskPath.hasSuffix("wrkstrm/services/takumi-fused/task.xml"))
    #expect(taskData.starts(with: [0xFF, 0xFE]))
    #expect(launcher.contains("C:\\Users\\operator\\.swiftpm\\bin\\takumi-fused.exe"))
    #expect(launcher.contains("$env:PATH = 'C:\\Users\\operator\\cuda;C:\\Windows\\System32'"))
    #expect(launcher.contains("$env:TAKUMI_MODEL = 'qwen'"))
    #expect(launcher.contains("$ErrorActionPreference = 'Continue'"))
    #expect(task.contains("<LogonTrigger>"))
    #expect(task.contains("encoding=\"UTF-16\""))
    #expect(task.contains("<RestartOnFailure>"))
    #expect(task.contains("<Interval>PT1M</Interval>"))
    #expect(task.contains("<LogonType>InteractiveToken</LogonType>"))
    #expect(command.executable == "schtasks.exe")
    #expect(command.arguments.contains("\\Wrkstrm\\Services\\takumi-fused"))
  }

  @Test("macOS install plan writes and bootstraps a user LaunchAgent")
  func rendersMacOSLaunchAgent() throws {
    var macService = service
    macService.executable = "~/.swiftpm/bin/takumi-fused"
    macService.workingDirectory = "~/models/takumi"
    macService.environment = ["TAKUMI_MODEL": "qwen"]
    let context = VaporizeServiceRuntimeContext(
      platform: .macos,
      homeDirectory: "/Users/operator",
      userIdentifier: "501"
    )
    let plan = try MacOSLaunchAgentServiceAdapter().plan(
      action: .install,
      serviceID: "takumi-fused",
      service: macService,
      context: context,
      environment: ["HOME": "/Users/operator"]
    )

    #expect(plan.backend == "macos-launch-agent")
    #expect(plan.steps.count == 6)
    guard case .write(let plistPath, let plistData) = plan.steps[3],
      case .command(let bootout) = plan.steps[4],
      case .command(let bootstrap) = plan.steps[5]
    else {
      Issue.record("macOS installation must write, replace, and bootstrap a LaunchAgent")
      return
    }
    let plist = try #require(
      PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
    )
    #expect(
      plistPath == "/Users/operator/Library/LaunchAgents/com.wrkstrm.service.takumi-fused.plist")
    #expect(plist["Label"] as? String == "com.wrkstrm.service.takumi-fused")
    #expect(plist["RunAtLoad"] as? Bool == true)
    #expect(plist["WorkingDirectory"] as? String == "/Users/operator/models/takumi")
    #expect(
      (plist["ProgramArguments"] as? [String])?.first == "/Users/operator/.swiftpm/bin/takumi-fused"
    )
    #expect(
      (plist["EnvironmentVariables"] as? [String: String])?["TAKUMI_MODEL"] == "qwen"
    )
    #expect(bootout.allowFailure)
    #expect(bootstrap.arguments.first == "bootstrap")
    #expect(bootstrap.arguments.contains("gui/501"))
  }

  @Test("System scope is rejected until an elevated contract exists")
  func rejectsSystemScope() {
    var systemService = service
    systemService.scope = .system
    let context = VaporizeServiceRuntimeContext(
      platform: .windows,
      homeDirectory: "C:\\Users\\operator",
      localApplicationDataDirectory: "C:\\Users\\operator\\AppData\\Local",
      accountName: "WORKSTATION\\operator"
    )
    #expect(throws: VaporizeServiceRegistrationError.unsupportedSystemScope) {
      try WindowsTaskSchedulerServiceAdapter().plan(
        action: .install,
        serviceID: "takumi-fused",
        service: systemService,
        context: context,
        environment: [:]
      )
    }
  }
}
