import Foundation
import Testing

@testable import VaporizeCLI

@Test("Vaporize persists the source-gate report before surfacing a Bead imprint failure")
func sourceGateImprintFailurePreservesReportReceipt() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    "vaporize-i18n-imprint-\(UUID().uuidString)",
    isDirectory: true
  )
  defer { try? FileManager.default.removeItem(at: root) }

  try FileManager.default.createDirectory(
    at: root.appendingPathComponent("Sources/App", isDirectory: true),
    withIntermediateDirectories: true
  )
  try """
    import Foundation

    print("Hello")
    """.write(
      to: root.appendingPathComponent("Sources/App/main.swift"),
      atomically: true,
      encoding: .utf8
    )

  let beadsDirectory = root.appendingPathComponent("beads", isDirectory: true)
  try FileManager.default.createDirectory(
    at: beadsDirectory,
    withIntermediateDirectories: true
  )
  try Data("{}\n".utf8).write(
    to: beadsDirectory.appendingPathComponent(
      "BUG-I18N-malformed.beads-issue.json"
    )
  )

  do {
    _ = try VaporizeI18nSourceGate.enforce(
      productDirectory: root,
      productName: "App",
      surfaceKind: .cli,
      enforcement: .release
    )
    Issue.record("Expected owner-local Bead reconciliation to fail.")
  } catch let error as VaporizeI18nSourceGateError {
    switch error {
    case .beadImprintFailed(let report, let receiptPath, let failure):
      #expect(report.targetName == "App")
      #expect(FileManager.default.fileExists(atPath: receiptPath))
      #expect(failure.contains("malformed"))
      #expect(error.localizedDescription.contains("Report receipt:"))
    case .blocked:
      Issue.record("Expected the explicit Bead imprint error after report persistence.")
    }
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
}

@Test("Vaporize blocking errors explain repair, proof, and the reconciled Bead handoff")
func sourceGateBlockedErrorIsAssistantActionable() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    "vaporize-i18n-actionable-\(UUID().uuidString)",
    isDirectory: true
  )
  defer { try? FileManager.default.removeItem(at: root) }

  try FileManager.default.createDirectory(
    at: root.appendingPathComponent("Sources/App", isDirectory: true),
    withIntermediateDirectories: true
  )
  try """
    import Foundation

    print("Hello")
    """.write(
      to: root.appendingPathComponent("Sources/App/main.swift"),
      atomically: true,
      encoding: .utf8
    )

  do {
    _ = try VaporizeI18nSourceGate.enforce(
      productDirectory: root,
      productName: "App",
      surfaceKind: .cli,
      enforcement: .release
    )
    Issue.record("Expected the source gate to block raw user-facing copy.")
  } catch let error as VaporizeI18nSourceGateError {
    switch error {
    case .blocked(_, let receipt, let reportPath, let imprintPath):
      #expect(receipt.summary.created > 0)
      #expect(FileManager.default.fileExists(atPath: reportPath))
      #expect(FileManager.default.fileExists(atPath: imprintPath))
      let rendered = error.localizedDescription
      #expect(rendered.contains("What happened:"))
      #expect(rendered.contains("Why it matters:"))
      #expect(rendered.contains("Next move:"))
      #expect(rendered.contains("Boundary:"))
      #expect(rendered.contains("Proof:"))
      #expect(rendered.contains("Policy:"))
      #expect(rendered.contains("cli-error-actionability.policy.su.json"))
      #expect(rendered.contains("Procedure:"))
      #expect(rendered.contains("cli-error-actionability.operating-protocol.su.json"))
      #expect(rendered.contains("Digikoma:"))
      #expect(rendered.contains("digikoma-cli-error-triage.spec.json"))
      #expect(rendered.contains("no installed command is claimed"))
      #expect(rendered.contains("Signal: NEW"))
      #expect(rendered.contains("Bead handling: Created BUG-I18N-"))
      #expect(rendered.contains("Assistant cast:"))
      #expect(rendered.contains("do not create a duplicate manually") == false)
    case .beadImprintFailed:
      Issue.record("Expected reconciliation to succeed before the descriptive block.")
    }
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
}

@Test("Vaporize reuses the complete established identity after a product display rename")
func sourceGateReusesEstablishedCompleteIdentity() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    "vaporize-i18n-complete-identity-\(UUID().uuidString)",
    isDirectory: true
  )
  defer { try? FileManager.default.removeItem(at: root) }
  try FileManager.default.createDirectory(
    at: root.appendingPathComponent("Sources/App", isDirectory: true),
    withIntermediateDirectories: true
  )
  try """
  import Foundation

  print("Hello")
  """.write(
    to: root.appendingPathComponent("Sources/App/main.swift"),
    atomically: true,
    encoding: .utf8
  )

  var firstTarget: String?
  do {
    _ = try VaporizeI18nSourceGate.enforce(
      productDirectory: root,
      productName: "EstablishedProduct",
      surfaceKind: .cli,
      enforcement: .release
    )
  } catch let error as VaporizeI18nSourceGateError {
    if case .blocked(let report, _, _, _) = error { firstTarget = report.targetName }
  }
  let beads = root.appendingPathComponent("beads", isDirectory: true)
  let firstIssueNames = try FileManager.default.contentsOfDirectory(
    at: beads,
    includingPropertiesForKeys: nil
  ).filter { $0.lastPathComponent.hasSuffix(".beads-issue.json") }
    .map(\.lastPathComponent)
    .sorted()

  var secondTarget: String?
  do {
    _ = try VaporizeI18nSourceGate.enforce(
      productDirectory: root,
      productName: "RenamedDisplayProduct",
      surfaceKind: .cli,
      enforcement: .release
    )
  } catch let error as VaporizeI18nSourceGateError {
    if case .blocked(let report, _, _, _) = error { secondTarget = report.targetName }
  }
  let secondIssueNames = try FileManager.default.contentsOfDirectory(
    at: beads,
    includingPropertiesForKeys: nil
  ).filter { $0.lastPathComponent.hasSuffix(".beads-issue.json") }
    .map(\.lastPathComponent)
    .sorted()

  #expect(firstTarget == "EstablishedProduct")
  #expect(secondTarget == "EstablishedProduct")
  #expect(!firstIssueNames.isEmpty)
  #expect(secondIssueNames == firstIssueNames)
}
