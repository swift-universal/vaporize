import CommonProcess
import CommonProcessExecutionKit
import Foundation

public struct VaporizeTestCommandOutput: Sendable {
  public let exitCode: Int32
  public let stdout: String
  public let stderr: String

  public init(exitCode: Int32, stdout: String, stderr: String) {
    self.exitCode = exitCode
    self.stdout = stdout
    self.stderr = stderr
  }
}

public enum VaporizeTestCommand {
  public static func run(
    executablePath: String,
    arguments: [String] = [],
    environment: [String: String] = [:],
    workingDirectory: String = FileManager.default.currentDirectoryPath,
    sourceTag: String
  ) async throws -> VaporizeTestCommandOutput {
    let command = CommandSpec(
      executable: .path(executablePath),
      args: arguments,
      env: .inherit(updating: environment),
      workingDirectory: workingDirectory,
      logOptions: .init(
        exposure: .none,
        tags: ["source": sourceTag]
      ),
      requestId: "\(sourceTag)-\(UUID().uuidString)",
      runnerKind: .auto,
      streamingMode: .buffered
    )
    try command.validateOrThrow()
    let output = try await RunnerControllerFactory.run(command: command)
    return VaporizeTestCommandOutput(
      exitCode: Int32(output.exitStatus.exitCode ?? 1),
      stdout: String(decoding: output.stdout, as: UTF8.self),
      stderr: String(decoding: output.stderr, as: UTF8.self)
    )
  }
}
