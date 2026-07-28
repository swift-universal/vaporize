import Foundation

#if os(macOS)
  import os
#endif

enum VaporizeCoreExecutionPhase: String, CaseIterable, Sendable {
  case coreCommand = "core-command"
  case dependencyPreparation = "dependency-preparation"
  case dependencyRestore = "dependency-restore"
  case processExecution = "process-execution"
}

struct VaporizeCoreExecutionTimingSnapshot: Equatable, Sendable {
  var commandElapsedNanoseconds: UInt64
  var dependencyPreparationNanoseconds: UInt64
  var dependencyRestoreNanoseconds: UInt64
  var processExecutionNanoseconds: UInt64
}

enum VaporizeCoreExecutionInstrumentation {
  @TaskLocal static var current: VaporizeCoreExecutionRecorder?
}

/// One recorder follows a core command across maintainer preparation, the
/// selected process authority, and package-resolution restoration. It emits
/// immediate phase transitions for terminal visibility, macOS signposts for
/// Instruments, and typed durations for retained receipts.
final class VaporizeCoreExecutionRecorder: @unchecked Sendable {
  let operation: VaporizeCoreOperation
  let authority: VaporizeCoreExecutionAuthority
  let resolver: String

  private let commandStarted = DispatchTime.now().uptimeNanoseconds
  private let lock = NSLock()
  private var elapsedByPhase: [VaporizeCoreExecutionPhase: UInt64] = [:]
  private var retainedTestReceipt: VaporizeTestReceipt?

  #if os(macOS)
    private static let signpostLog = OSLog(
      subsystem: "studio.laussat.vaporize",
      category: "core-execution"
    )
    private let signpostID = OSSignpostID(log: signpostLog)
  #endif

  init(plan: VaporizeCoreExecutionPlan) {
    operation = plan.operation
    authority = plan.executionAuthority
    resolver = plan.toolchainResolver
  }

  func measure<Result>(
    _ phase: VaporizeCoreExecutionPhase,
    operation body: () async throws -> Result
  ) async rethrows -> Result {
    let started = DispatchTime.now().uptimeNanoseconds
    emitTransition(phase: phase, state: "begin", elapsedNanoseconds: nil)
    defer {
      let elapsed = DispatchTime.now().uptimeNanoseconds &- started
      lock.withLock {
        elapsedByPhase[phase, default: 0] &+= elapsed
      }
      emitTransition(phase: phase, state: "end", elapsedNanoseconds: elapsed)
    }
    return try await body()
  }

  func snapshot() -> VaporizeCoreExecutionTimingSnapshot {
    let durations = lock.withLock { elapsedByPhase }
    return VaporizeCoreExecutionTimingSnapshot(
      commandElapsedNanoseconds: DispatchTime.now().uptimeNanoseconds &- commandStarted,
      dependencyPreparationNanoseconds: durations[.dependencyPreparation, default: 0],
      dependencyRestoreNanoseconds: durations[.dependencyRestore, default: 0],
      processExecutionNanoseconds: durations[.processExecution, default: 0]
    )
  }

  func retain(_ receipt: VaporizeTestReceipt) {
    lock.withLock {
      retainedTestReceipt = receipt
    }
  }

  func takeFinalizedTestReceipt() -> VaporizeTestReceipt? {
    let timing = snapshot()
    return lock.withLock {
      guard var receipt = retainedTestReceipt else { return nil }
      retainedTestReceipt = nil
      receipt.commandElapsedNanoseconds = timing.commandElapsedNanoseconds
      receipt.dependencyPreparationNanoseconds = timing.dependencyPreparationNanoseconds
      receipt.dependencyRestoreNanoseconds = timing.dependencyRestoreNanoseconds
      receipt.processExecutionNanoseconds = timing.processExecutionNanoseconds
      return receipt
    }
  }

  private func emitTransition(
    phase: VaporizeCoreExecutionPhase,
    state: String,
    elapsedNanoseconds: UInt64?
  ) {
    let elapsed =
      elapsedNanoseconds.map {
        String(format: " elapsed-ms=%.3f", Double($0) / 1_000_000)
      } ?? ""
    let message =
      "phase=\(phase.rawValue) state=\(state) operation=\(operation.rawValue) authority=\(authority.rawValue) resolver=\(resolver)\(elapsed)"
    if state == "begin" {
      VaporizeLogging.coreExecution.trace(message)
    } else {
      VaporizeLogging.coreExecution.debug(message)
    }

    #if os(macOS)
      let signpostType: OSSignpostType = state == "begin" ? .begin : .end
      os_signpost(
        signpostType,
        log: Self.signpostLog,
        name: "VaporizeCorePhase",
        signpostID: signpostID,
        "phase=%{public}@ operation=%{public}@ authority=%{public}@ resolver=%{public}@",
        phase.rawValue as NSString,
        operation.rawValue as NSString,
        authority.rawValue as NSString,
        resolver as NSString
      )
    #endif
  }
}
