import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-21 derives CUJ state from critical user journeys")
func derivesCUJStateFromCUJs() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-21-state-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: root) }

  let harness = VaporizeCUJStateHarness(rootDirectory: root, storehouseFamily: "kura-org")
  let receipt = try harness.prepare(
    VaporizeCUJStateSpec(
      stateSlug: "SCM Product Suite",
      stateTitle: "SCM product suite CUJ state",
      cujs: [
        VaporizeCriticalUserJourney(
          slug: "savepoint emits boundary aware commit",
          title: "Savepoint emits a boundary-aware commit",
          actor: "software modification steward",
          intent: "persist a change without crossing git ownership boundaries",
          preconditions: [
            "a component-home bead exists",
            "the working tree has an owned file list",
          ],
          actions: [
            "validate edited typed records",
            "emit savepoint for the nested owner",
            "emit parent gitlink savepoint",
          ],
          outcomes: [
            "savepoint event id exists",
            "parent pointer is updated",
          ],
          tags: ["scm", "savepoint", "cuj-state"]
        ),
        VaporizeCriticalUserJourney(
          slug: "vaporize verifies package lane",
          title: "Vaporize verifies a package lane",
          actor: "proof gate engineer",
          intent: "prove a Swift package through the canonical Vaporize lane",
          actions: [
            "run Vaporize test mode",
            "record the command receipt",
          ],
          outcomes: [
            "test count is known",
            "toolchain is visible",
          ],
          tags: ["vaporize", "proof-lane"]
        ),
      ],
      metadata: [
        "collective": "kura-org",
        "productLine": "scm",
      ]
    ),
    createdAt: Date(timeIntervalSince1970: 0)
  )

  #expect(receipt.harnessKind == "cuj-state-harness")
  #expect(receipt.stateFamily == "cuj-state")
  #expect(receipt.storehouseFamily == "kura-org")
  #expect(receipt.stateSlug == "scm-product-suite")
  #expect(receipt.cujCount == 2)
  #expect(receipt.stateRecordCount == 2)
  #expect(receipt.sourceKind == "critical-user-journey")
  #expect(receipt.metadata["collective"] == "kura-org")
  #expect(receipt.createdAt == "1970-01-01T00:00:00Z")

  #expect(FileManager.default.fileExists(atPath: receipt.cujManifestPath))
  #expect(FileManager.default.fileExists(atPath: receipt.statePath))
  #expect(FileManager.default.fileExists(atPath: receipt.receiptPath))

  let stateData = try Data(contentsOf: URL(fileURLWithPath: receipt.statePath))
  let stateDocument = try JSONDecoder().decode(VaporizeCUJStateDocument.self, from: stateData)

  #expect(stateDocument.documentKind == "cuj-state")
  #expect(stateDocument.sourceKind == "critical-user-journey")
  #expect(stateDocument.records.map(\.sourceCUJSlug) == [
    "savepoint-emits-boundary-aware-commit",
    "vaporize-verifies-package-lane",
  ])
  #expect(stateDocument.records.first?.actor == "software modification steward")
  #expect(stateDocument.records.first?.outcomes.contains("parent pointer is updated") == true)
}

@Test("CUJ-21 keeps CUJ state receipts independent of database engines")
func cujStateReceiptDoesNotExposeDatabaseEngine() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-21-state-minimal-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: root) }

  let harness = VaporizeCUJStateHarness(rootDirectory: root)
  let receipt = try harness.prepare(
    VaporizeCUJStateSpec(
      stateSlug: "operator review",
      stateTitle: "Operator review CUJ state",
      cujs: [
        VaporizeCriticalUserJourney(
          slug: "review milestone",
          title: "Review milestone",
          actor: "chair",
          intent: "decide whether a milestone can advance",
          outcomes: ["decision is recorded"]
        ),
      ]
    )
  )

  let receiptData = try Data(contentsOf: URL(fileURLWithPath: receipt.receiptPath))
  let receiptText = try #require(String(data: receiptData, encoding: .utf8))

  #expect(receipt.stateFamily == "cuj-state")
  #expect(receipt.storehouseFamily == nil)
  #expect(receiptText.contains("turso") == false)
  #expect(receiptText.contains("libsql") == false)
  #expect(receiptText.contains("databaseURL") == false)
  #expect(receiptText.contains("database-engine") == false)
  #expect(receiptText.contains("kura-world") == false)
}

@Test("CUJ-21 CUJ state receipts round-trip through Codable")
func cujStateReceiptRoundTrips() throws {
  let receipt = VaporizeCUJStateReceipt(
    schemaVersion: "0.1.0",
    harnessKind: "cuj-state-harness",
    stateFamily: "cuj-state",
    storehouseFamily: "kura-org",
    stateSlug: "round-trip",
    rootPath: "/tmp/root",
    cujManifestPath: "/tmp/root/cujs.json",
    statePath: "/tmp/root/cuj-state.json",
    receiptPath: "/tmp/root/cuj-state.receipt.json",
    cujCount: 2,
    stateRecordCount: 2,
    sourceKind: "critical-user-journey",
    metadata: ["lane": "unit-test"],
    createdAt: "1970-01-01T00:00:00Z"
  )

  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(VaporizeCUJStateReceipt.self, from: data)

  #expect(decoded == receipt)
}

@Test("CUJ-21 coverage gate passes only when every CUJ state has proof")
func cujStateCoverageGateRequiresEveryStateID() throws {
  let fixture = try makeCoverageFixture()
  defer { try? FileManager.default.removeItem(at: fixture.root) }

  let proofs = fixture.document.records.map { record in
    VaporizeCUJStateProof(
      stateID: record.id,
      proofKind: "behavior-proof",
      testTarget: "VaporizeCUJ21CUJStateTests",
      testName: "cujStateCoverageGateRequiresEveryStateID",
      receiptRef: "command-receipt://vaporize/cuj21-cuj-state/coverage-gate"
    )
  }
  let manifest = VaporizeCUJStateCoverageGate.manifest(
    document: fixture.document,
    statePath: fixture.receipt.statePath,
    proofs: proofs,
    createdAt: Date(timeIntervalSince1970: 0)
  )

  #expect(manifest.documentKind == "cuj-state-coverage")
  #expect(manifest.coverageStatus == "pass")
  #expect(manifest.requiredStateIDs == fixture.document.records.map(\.id).sorted())
  #expect(manifest.coveredStateIDs == manifest.requiredStateIDs)
  #expect(manifest.uncoveredStateIDs.isEmpty)
  #expect(manifest.unknownStateIDs.isEmpty)
  #expect(manifest.createdAt == "1970-01-01T00:00:00Z")

  let coverageURL = try fixture.harness.writeCoverageManifest(
    document: fixture.document,
    statePath: fixture.receipt.statePath,
    proofs: proofs,
    createdAt: Date(timeIntervalSince1970: 0)
  )
  let coverageData = try Data(contentsOf: coverageURL)
  let decoded = try JSONDecoder().decode(VaporizeCUJStateCoverageManifest.self, from: coverageData)

  #expect(decoded == manifest)
  #expect(coverageURL.lastPathComponent == "cuj-state.coverage.json")
}

@Test("CUJ-21 coverage gate fails when a CUJ state is uncovered")
func cujStateCoverageGateFailsMissingStateID() throws {
  let fixture = try makeCoverageFixture()
  defer { try? FileManager.default.removeItem(at: fixture.root) }
  let firstRecord = try #require(fixture.document.records.first)
  let lastRecord = try #require(fixture.document.records.last)
  let manifest = VaporizeCUJStateCoverageGate.manifest(
    document: fixture.document,
    statePath: fixture.receipt.statePath,
    proofs: [
      VaporizeCUJStateProof(
        stateID: firstRecord.id,
        proofKind: "behavior-proof",
        testTarget: "VaporizeCUJ21CUJStateTests",
        testName: "cujStateCoverageGateFailsMissingStateID",
        receiptRef: "command-receipt://vaporize/cuj21-cuj-state/missing-state"
      )
    ],
    createdAt: Date(timeIntervalSince1970: 0)
  )

  #expect(manifest.coverageStatus == "fail")
  #expect(manifest.coveredStateIDs == [firstRecord.id])
  #expect(manifest.uncoveredStateIDs == [lastRecord.id])
  #expect(manifest.unknownStateIDs.isEmpty)
}

@Test("CUJ-21 coverage gate fails when proof claims an unknown CUJ state")
func cujStateCoverageGateFailsUnknownStateID() throws {
  let fixture = try makeCoverageFixture()
  defer { try? FileManager.default.removeItem(at: fixture.root) }
  let proofs = fixture.document.records.map { record in
    VaporizeCUJStateProof(
      stateID: record.id,
      proofKind: "behavior-proof",
      testTarget: "VaporizeCUJ21CUJStateTests",
      testName: "cujStateCoverageGateFailsUnknownStateID",
      receiptRef: "command-receipt://vaporize/cuj21-cuj-state/unknown-state"
    )
  } + [
    VaporizeCUJStateProof(
      stateID: "scm-product-suite.cuj.unknown-state",
      proofKind: "behavior-proof",
      testTarget: "VaporizeCUJ21CUJStateTests",
      testName: "cujStateCoverageGateFailsUnknownStateID",
      receiptRef: "command-receipt://vaporize/cuj21-cuj-state/unknown-state"
    )
  ]

  let manifest = VaporizeCUJStateCoverageGate.manifest(
    document: fixture.document,
    statePath: fixture.receipt.statePath,
    proofs: proofs,
    createdAt: Date(timeIntervalSince1970: 0)
  )

  #expect(manifest.coverageStatus == "fail")
  #expect(manifest.uncoveredStateIDs.isEmpty)
  #expect(manifest.unknownStateIDs == ["scm-product-suite.cuj.unknown-state"])
}

private struct CUJStateCoverageFixture {
  var root: URL
  var harness: VaporizeCUJStateHarness
  var receipt: VaporizeCUJStateReceipt
  var document: VaporizeCUJStateDocument
}

private func makeCoverageFixture() throws -> CUJStateCoverageFixture {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-21-coverage-\(UUID().uuidString)")
  let harness = VaporizeCUJStateHarness(rootDirectory: root, storehouseFamily: "kura-org")
  let receipt = try harness.prepare(
    VaporizeCUJStateSpec(
      stateSlug: "SCM Product Suite",
      stateTitle: "SCM product suite CUJ state",
      cujs: [
        VaporizeCriticalUserJourney(
          slug: "savepoint emits boundary aware commit",
          title: "Savepoint emits a boundary-aware commit",
          actor: "software modification steward",
          intent: "persist a change without crossing git ownership boundaries"
        ),
        VaporizeCriticalUserJourney(
          slug: "vaporize verifies package lane",
          title: "Vaporize verifies a package lane",
          actor: "proof gate engineer",
          intent: "prove a Swift package through the canonical Vaporize lane"
        ),
      ],
      metadata: [
        "collective": "kura-org",
        "productLine": "scm",
      ]
    ),
    createdAt: Date(timeIntervalSince1970: 0)
  )

  let stateData = try Data(contentsOf: URL(fileURLWithPath: receipt.statePath))
  let document = try JSONDecoder().decode(VaporizeCUJStateDocument.self, from: stateData)
  return CUJStateCoverageFixture(root: root, harness: harness, receipt: receipt, document: document)
}
