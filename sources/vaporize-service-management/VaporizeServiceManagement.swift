import CommonProcess
import CommonShell
import Foundation
import VaporizeProjectModel

public enum VaporizeServiceAction: String, CaseIterable, Equatable, Sendable {
  case install
  case start
  case status
  case logs
  case stop
  case uninstall
}

public enum VaporizeServiceHostPlatform: String, Codable, Equatable, Sendable {
  case windows
  case macos
  case linux

  public static func detect(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    fileExists: (String) -> Bool = FileManager.default.fileExists(atPath:)
  ) -> Self {
    if environment["OS"]?.lowercased() == "windows_nt" { return .windows }
    if fileExists("/System/Library/CoreServices") { return .macos }
    return .linux
  }
}

public struct VaporizeServiceRuntimeContext: Equatable, Sendable {
  public var platform: VaporizeServiceHostPlatform
  public var homeDirectory: String
  public var localApplicationDataDirectory: String?
  public var accountName: String?
  public var userIdentifier: String?

  public init(
    platform: VaporizeServiceHostPlatform,
    homeDirectory: String,
    localApplicationDataDirectory: String? = nil,
    accountName: String? = nil,
    userIdentifier: String? = nil
  ) {
    self.platform = platform
    self.homeDirectory = homeDirectory
    self.localApplicationDataDirectory = localApplicationDataDirectory
    self.accountName = accountName
    self.userIdentifier = userIdentifier
  }
}

public struct VaporizeNativeCommand: Equatable, Sendable {
  public var executable: String
  public var arguments: [String]
  public var allowFailure: Bool

  public init(executable: String, arguments: [String], allowFailure: Bool = false) {
    self.executable = executable
    self.arguments = arguments
    self.allowFailure = allowFailure
  }
}

public enum VaporizeServicePlanStep: Equatable, Sendable {
  case createDirectory(path: String)
  case write(path: String, contents: Data)
  case remove(path: String)
  case command(VaporizeNativeCommand)
}

public struct VaporizeServiceRegistrationPlan: Equatable, Sendable {
  public var serviceID: String
  public var action: VaporizeServiceAction
  public var backend: String
  public var standardOutputPath: String
  public var standardErrorPath: String
  public var steps: [VaporizeServicePlanStep]

  public init(
    serviceID: String,
    action: VaporizeServiceAction,
    backend: String,
    standardOutputPath: String,
    standardErrorPath: String,
    steps: [VaporizeServicePlanStep]
  ) {
    self.serviceID = serviceID
    self.action = action
    self.backend = backend
    self.standardOutputPath = standardOutputPath
    self.standardErrorPath = standardErrorPath
    self.steps = steps
  }
}

public struct VaporizeServiceActionReceipt: Codable, Equatable, Sendable {
  public var schemaVersion: String
  public var serviceID: String
  public var action: String
  public var backend: String
  public var standardOutputPath: String
  public var standardErrorPath: String
  public var commandOutput: [String]

  public init(plan: VaporizeServiceRegistrationPlan, commandOutput: [String]) {
    schemaVersion = "0.1.0"
    serviceID = plan.serviceID
    action = plan.action.rawValue
    backend = plan.backend
    standardOutputPath = plan.standardOutputPath
    standardErrorPath = plan.standardErrorPath
    self.commandOutput = commandOutput
  }
}

public enum VaporizeServiceRegistrationError: Error, CustomStringConvertible, Equatable {
  case serviceNotFound(String)
  case invalidServiceID(String)
  case unsupportedSystemScope
  case unsupportedPlatform(VaporizeServiceHostPlatform)
  case missingContext(String)
  case invalidExecutable(String)

  public var description: String {
    switch self {
    case .serviceNotFound(let serviceID):
      "project.pkl does not declare service '\(serviceID)'."
    case .invalidServiceID(let serviceID):
      "service id '\(serviceID)' must use lowercase kebab case."
    case .unsupportedSystemScope:
      "system-scoped service registration is not implemented; use scope = \"user\"."
    case .unsupportedPlatform(let platform):
      "service registration is not implemented for \(platform.rawValue)."
    case .missingContext(let field):
      "service registration could not resolve required host context '\(field)'."
    case .invalidExecutable(let executable):
      "service executable resolves to an empty path: '\(executable)'."
    }
  }
}

public protocol VaporizeServiceRegistrationAdapter {
  func plan(
    action: VaporizeServiceAction,
    serviceID: String,
    service: VaporizeService,
    context: VaporizeServiceRuntimeContext,
    environment: [String: String]
  ) throws -> VaporizeServiceRegistrationPlan
}

public enum VaporizeServiceRegistrationAdapterFactory {
  public static func make(
    for platform: VaporizeServiceHostPlatform
  ) throws -> any VaporizeServiceRegistrationAdapter {
    switch platform {
    case .windows: WindowsTaskSchedulerServiceAdapter()
    case .macos: MacOSLaunchAgentServiceAdapter()
    case .linux: throw VaporizeServiceRegistrationError.unsupportedPlatform(.linux)
    }
  }
}

public struct VaporizeServiceManager {
  private let fileManager: FileManager
  private let environment: [String: String]

  public init(
    fileManager: FileManager = .default,
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) {
    self.fileManager = fileManager
    self.environment = environment
  }

  public func perform(
    action: VaporizeServiceAction,
    serviceID: String,
    project: VaporizeProject
  ) async throws -> VaporizeServiceActionReceipt {
    guard let service = project.services[serviceID] else {
      throw VaporizeServiceRegistrationError.serviceNotFound(serviceID)
    }
    let platform = VaporizeServiceHostPlatform.detect(
      environment: environment,
      fileExists: fileManager.fileExists(atPath:)
    )
    let context = try await runtimeContext(platform: platform)
    let adapter = try VaporizeServiceRegistrationAdapterFactory.make(for: platform)
    let plan = try adapter.plan(
      action: action,
      serviceID: serviceID,
      service: service,
      context: context,
      environment: environment
    )

    var commandOutput: [String] = []
    for step in plan.steps {
      switch step {
      case .createDirectory(let path):
        try fileManager.createDirectory(
          at: URL(fileURLWithPath: path),
          withIntermediateDirectories: true
        )
      case .write(let path, let contents):
        let url = URL(fileURLWithPath: path)
        try fileManager.createDirectory(
          at: url.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        try contents.write(to: url, options: .atomic)
      case .remove(let path):
        if fileManager.fileExists(atPath: path) {
          try fileManager.removeItem(atPath: path)
        }
      case .command(let command):
        let shell = CommonShell(executable: .name(command.executable))
        do {
          let output = try await shell.run(command.arguments)
          let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty { commandOutput.append(trimmed) }
        } catch {
          if !command.allowFailure { throw error }
        }
      }
    }
    return VaporizeServiceActionReceipt(plan: plan, commandOutput: commandOutput)
  }

  private func runtimeContext(
    platform: VaporizeServiceHostPlatform
  ) async throws -> VaporizeServiceRuntimeContext {
    let home = environment["USERPROFILE"] ?? environment["HOME"] ?? NSHomeDirectory()
    var userIdentifier = environment["UID"]
    if platform == .macos && userIdentifier == nil {
      let shell = CommonShell(executable: .name("id"))
      userIdentifier = try await shell.run(["-u"])
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let accountName: String? = {
      guard let username = environment["USERNAME"] else { return nil }
      guard let domain = environment["USERDOMAIN"], !domain.isEmpty else { return username }
      return "\(domain)\\\(username)"
    }()
    return VaporizeServiceRuntimeContext(
      platform: platform,
      homeDirectory: home,
      localApplicationDataDirectory: environment["LOCALAPPDATA"],
      accountName: accountName,
      userIdentifier: userIdentifier
    )
  }
}

public struct WindowsTaskSchedulerServiceAdapter: VaporizeServiceRegistrationAdapter {
  public init() {}

  public func plan(
    action: VaporizeServiceAction,
    serviceID: String,
    service: VaporizeService,
    context: VaporizeServiceRuntimeContext,
    environment: [String: String]
  ) throws -> VaporizeServiceRegistrationPlan {
    try validate(serviceID: serviceID, service: service)
    guard let localApplicationDataDirectory = context.localApplicationDataDirectory else {
      throw VaporizeServiceRegistrationError.missingContext("LOCALAPPDATA")
    }
    guard let accountName = context.accountName else {
      throw VaporizeServiceRegistrationError.missingContext("Windows account name")
    }

    let supportDirectory = URL(fileURLWithPath: localApplicationDataDirectory)
      .appendingPathComponent("wrkstrm/services/\(serviceID)").path
    let launcherPath = URL(fileURLWithPath: supportDirectory).appendingPathComponent("launch.cmd")
      .path
    let taskXMLPath = URL(fileURLWithPath: supportDirectory).appendingPathComponent("task.xml").path
    let stdout = resolvePath(
      service.standardOutputPath ?? "\(supportDirectory)/stdout.log",
      context: context,
      environment: environment
    )
    let stderr = resolvePath(
      service.standardErrorPath ?? "\(supportDirectory)/stderr.log",
      context: context,
      environment: environment
    )
    let taskName = "\\Wrkstrm\\Services\\\(serviceID)"
    var steps: [VaporizeServicePlanStep] = []

    switch action {
    case .install:
      let launcher = renderCommandLauncher(
        service: service,
        context: context,
        environment: environment,
        stdout: stdout,
        stderr: stderr
      )
      let taskXML = renderTaskXML(
        serviceID: serviceID,
        service: service,
        accountName: accountName,
        launcherPath: launcherPath
      )
      steps = [
        .createDirectory(path: supportDirectory),
        .createDirectory(path: URL(fileURLWithPath: stdout).deletingLastPathComponent().path),
        .createDirectory(path: URL(fileURLWithPath: stderr).deletingLastPathComponent().path),
        .write(path: launcherPath, contents: Data(launcher.utf8)),
        .write(path: taskXMLPath, contents: utf16LittleEndianData(taskXML)),
        .command(
          .init(
            executable: "schtasks.exe",
            arguments: ["/Create", "/TN", taskName, "/XML", taskXMLPath, "/F"]
          )),
      ]
    case .start:
      steps = [.command(.init(executable: "schtasks.exe", arguments: ["/Run", "/TN", taskName]))]
    case .status:
      steps = [
        .command(
          .init(
            executable: "schtasks.exe",
            arguments: ["/Query", "/TN", taskName, "/FO", "LIST", "/V"]
          ))
      ]
    case .logs:
      steps = []
    case .stop:
      steps = [
        .command(
          .init(
            executable: "schtasks.exe",
            arguments: ["/End", "/TN", taskName],
            allowFailure: true
          ))
      ]
    case .uninstall:
      steps = [
        .command(
          .init(
            executable: "schtasks.exe",
            arguments: ["/Delete", "/TN", taskName, "/F"],
            allowFailure: true
          )),
        .remove(path: taskXMLPath),
        .remove(path: launcherPath),
      ]
    }

    return VaporizeServiceRegistrationPlan(
      serviceID: serviceID,
      action: action,
      backend: "windows-task-scheduler",
      standardOutputPath: stdout,
      standardErrorPath: stderr,
      steps: steps
    )
  }

  private func renderCommandLauncher(
    service: VaporizeService,
    context: VaporizeServiceRuntimeContext,
    environment: [String: String],
    stdout: String,
    stderr: String
  ) -> String {
    let executable = resolvePath(service.executable, context: context, environment: environment)
    let workingDirectory = resolvePath(
      service.workingDirectory ?? URL(fileURLWithPath: executable).deletingLastPathComponent().path,
      context: context,
      environment: environment
    )
    let environmentLines = service.environment.keys.sorted().map { key in
      let value = resolvePath(
        service.environment[key] ?? "",
        context: context,
        environment: environment
      )
      return "set \"\(key)=\(batchLiteral(value))\""
    }
    let arguments = service.arguments.map { "\"\(batchLiteral($0))\"" }.joined(separator: " ")
    return
      ([
        "@echo off",
        "setlocal DisableDelayedExpansion",
      ] + environmentLines + [
        "cd /d \"\(batchLiteral(workingDirectory))\"",
        "\"\(batchLiteral(executable))\" \(arguments) 1>>\"\(batchLiteral(stdout))\" 2>>\"\(batchLiteral(stderr))\"",
        "exit /b %ERRORLEVEL%",
        "",
      ]).joined(separator: "\r\n")
  }

  private func renderTaskXML(
    serviceID: String,
    service: VaporizeService,
    accountName: String,
    launcherPath: String
  ) -> String {
    let trigger =
      service.activation == .login
      ? """
        <LogonTrigger>
          <Enabled>true</Enabled>
          <UserId>\(xml(accountName))</UserId>
        </LogonTrigger>
      """
      : ""
    let restart =
      service.restartPolicy == .never
      ? ""
      : """
        <RestartOnFailure>
          <Interval>PT1M</Interval>
          <Count>3</Count>
        </RestartOnFailure>
      """
    return """
      <?xml version="1.0" encoding="UTF-16"?>
      <Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
        <RegistrationInfo>
          <Description>Vaporize managed user service: \(xml(serviceID))</Description>
        </RegistrationInfo>
        <Triggers>
      \(trigger)
        </Triggers>
        <Principals>
          <Principal id="Author">
            <UserId>\(xml(accountName))</UserId>
            <LogonType>InteractiveToken</LogonType>
            <RunLevel>LeastPrivilege</RunLevel>
          </Principal>
        </Principals>
        <Settings>
          <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
          <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
          <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
          <AllowHardTerminate>true</AllowHardTerminate>
          <StartWhenAvailable>true</StartWhenAvailable>
          <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
      \(restart)
        </Settings>
        <Actions Context="Author">
          <Exec>
            <Command>cmd.exe</Command>
            <Arguments>/D /S /C &quot;&quot;\(xml(launcherPath))&quot;&quot;</Arguments>
          </Exec>
        </Actions>
      </Task>
      """
  }
}

public struct MacOSLaunchAgentServiceAdapter: VaporizeServiceRegistrationAdapter {
  public init() {}

  public func plan(
    action: VaporizeServiceAction,
    serviceID: String,
    service: VaporizeService,
    context: VaporizeServiceRuntimeContext,
    environment: [String: String]
  ) throws -> VaporizeServiceRegistrationPlan {
    try validate(serviceID: serviceID, service: service)
    guard let userIdentifier = context.userIdentifier, !userIdentifier.isEmpty else {
      throw VaporizeServiceRegistrationError.missingContext("UID")
    }
    let label = "com.wrkstrm.service.\(serviceID)"
    let target = "gui/\(userIdentifier)/\(label)"
    let plistPath = URL(fileURLWithPath: context.homeDirectory)
      .appendingPathComponent("Library/LaunchAgents/\(label).plist").path
    let supportDirectory = URL(fileURLWithPath: context.homeDirectory)
      .appendingPathComponent("Library/Application Support/wrkstrm/services/\(serviceID)").path
    let stdout = resolvePath(
      service.standardOutputPath ?? "\(supportDirectory)/stdout.log",
      context: context,
      environment: environment
    )
    let stderr = resolvePath(
      service.standardErrorPath ?? "\(supportDirectory)/stderr.log",
      context: context,
      environment: environment
    )
    var steps: [VaporizeServicePlanStep] = []

    switch action {
    case .install:
      let plist = try renderPlist(
        label: label,
        service: service,
        context: context,
        environment: environment,
        stdout: stdout,
        stderr: stderr
      )
      steps = [
        .createDirectory(path: supportDirectory),
        .createDirectory(path: URL(fileURLWithPath: stdout).deletingLastPathComponent().path),
        .createDirectory(path: URL(fileURLWithPath: stderr).deletingLastPathComponent().path),
        .write(path: plistPath, contents: plist),
        .command(
          .init(
            executable: "launchctl",
            arguments: ["bootout", "gui/\(userIdentifier)", plistPath],
            allowFailure: true
          )),
        .command(
          .init(
            executable: "launchctl",
            arguments: ["bootstrap", "gui/\(userIdentifier)", plistPath]
          )),
      ]
    case .start:
      steps = [.command(.init(executable: "launchctl", arguments: ["kickstart", "-k", target]))]
    case .status:
      steps = [.command(.init(executable: "launchctl", arguments: ["print", target]))]
    case .logs:
      steps = []
    case .stop:
      steps = [
        .command(
          .init(
            executable: "launchctl",
            arguments: ["kill", "SIGTERM", target],
            allowFailure: true
          ))
      ]
    case .uninstall:
      steps = [
        .command(
          .init(
            executable: "launchctl",
            arguments: ["bootout", "gui/\(userIdentifier)", plistPath],
            allowFailure: true
          )),
        .remove(path: plistPath),
      ]
    }
    return VaporizeServiceRegistrationPlan(
      serviceID: serviceID,
      action: action,
      backend: "macos-launch-agent",
      standardOutputPath: stdout,
      standardErrorPath: stderr,
      steps: steps
    )
  }

  private func renderPlist(
    label: String,
    service: VaporizeService,
    context: VaporizeServiceRuntimeContext,
    environment: [String: String],
    stdout: String,
    stderr: String
  ) throws -> Data {
    let executable = resolvePath(service.executable, context: context, environment: environment)
    var plist: [String: Any] = [
      "Label": label,
      "ProgramArguments": [executable] + service.arguments,
      "RunAtLoad": service.activation == .login,
      "StandardOutPath": stdout,
      "StandardErrorPath": stderr,
      "ProcessType": "Background",
    ]
    if let workingDirectory = service.workingDirectory {
      plist["WorkingDirectory"] = resolvePath(
        workingDirectory,
        context: context,
        environment: environment
      )
    }
    if !service.environment.isEmpty {
      plist["EnvironmentVariables"] = service.environment.mapValues {
        resolvePath($0, context: context, environment: environment)
      }
    }
    switch service.restartPolicy {
    case .never: break
    case .onFailure: plist["KeepAlive"] = ["SuccessfulExit": false]
    case .always: plist["KeepAlive"] = true
    }
    return try PropertyListSerialization.data(
      fromPropertyList: plist,
      format: .xml,
      options: 0
    )
  }
}

private func validate(serviceID: String, service: VaporizeService) throws {
  let pieces = serviceID.split(separator: "-", omittingEmptySubsequences: false)
  let valid =
    !pieces.isEmpty
    && pieces.allSatisfy { piece in
      !piece.isEmpty && piece.allSatisfy { $0.isLowercase || $0.isNumber }
    }
  guard valid else { throw VaporizeServiceRegistrationError.invalidServiceID(serviceID) }
  guard service.scope == .user else {
    throw VaporizeServiceRegistrationError.unsupportedSystemScope
  }
  guard !service.executable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
    throw VaporizeServiceRegistrationError.invalidExecutable(service.executable)
  }
}

private func resolvePath(
  _ rawPath: String,
  context: VaporizeServiceRuntimeContext,
  environment: [String: String]
) -> String {
  var result = rawPath
  if result == "~" {
    result = context.homeDirectory
  } else if result.hasPrefix("~/") || result.hasPrefix("~\\") {
    result =
      URL(fileURLWithPath: context.homeDirectory)
      .appendingPathComponent(String(result.dropFirst(2))).path
  }
  for (key, value) in environment.sorted(by: { $0.key.count > $1.key.count }) {
    result = result.replacingOccurrences(
      of: "%\(key)%",
      with: value,
      options: .caseInsensitive
    )
    result = result.replacingOccurrences(of: "${\(key)}", with: value)
  }
  return result
}

private func batchLiteral(_ value: String) -> String {
  value
    .replacingOccurrences(of: "^", with: "^^")
    .replacingOccurrences(of: "%", with: "%%")
    .replacingOccurrences(of: "\"", with: "^\"")
}

private func utf16LittleEndianData(_ value: String) -> Data {
  var data = Data([0xFF, 0xFE])
  for codeUnit in value.utf16 {
    data.append(UInt8(codeUnit & 0x00FF))
    data.append(UInt8(codeUnit >> 8))
  }
  return data
}

private func xml(_ value: String) -> String {
  value
    .replacingOccurrences(of: "&", with: "&amp;")
    .replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
    .replacingOccurrences(of: "\"", with: "&quot;")
    .replacingOccurrences(of: "'", with: "&apos;")
}
