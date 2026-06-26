import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-21 derives Kura world seed state from critical user journeys")
func derivesKuraWorldSeedStateFromCUJs() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-21-kura-world-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: root) }

  let harness = VaporizeKuraWorldSeedStateHarness(rootDirectory: root)
  let receipt = try harness.prepare(
    VaporizeKuraWorldSeedStateSpec(
      worldSlug: "SCM Product Suite",
      worldTitle: "SCM product suite simulated world",
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
          tags: ["scm", "savepoint", "kura-world"]
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

  #expect(receipt.harnessKind == "kura-world-seed-state-harness")
  #expect(receipt.storageFamily == "kura")
  #expect(receipt.worldSlug == "scm-product-suite")
  #expect(receipt.cujCount == 2)
  #expect(receipt.seedRecordCount == 2)
  #expect(receipt.sourceKind == "critical-user-journey")
  #expect(receipt.metadata["collective"] == "kura-org")
  #expect(receipt.createdAt == "1970-01-01T00:00:00Z")

  #expect(FileManager.default.fileExists(atPath: receipt.cujManifestPath))
  #expect(FileManager.default.fileExists(atPath: receipt.seedStatePath))
  #expect(FileManager.default.fileExists(atPath: receipt.receiptPath))

  let seedData = try Data(contentsOf: URL(fileURLWithPath: receipt.seedStatePath))
  let seedDocument = try JSONDecoder().decode(VaporizeKuraWorldSeedDocument.self, from: seedData)

  #expect(seedDocument.documentKind == "kura-world-seed-state")
  #expect(seedDocument.sourceKind == "critical-user-journey")
  #expect(seedDocument.records.map(\.sourceCUJSlug) == [
    "savepoint-emits-boundary-aware-commit",
    "vaporize-verifies-package-lane",
  ])
  #expect(seedDocument.records.first?.actor == "software modification steward")
  #expect(seedDocument.records.first?.outcomes.contains("parent pointer is updated") == true)
}

@Test("CUJ-21 keeps Kura world seed-state receipts independent of database engines")
func seedStateReceiptDoesNotExposeDatabaseEngine() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-21-kura-world-minimal-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: root) }

  let harness = VaporizeKuraWorldSeedStateHarness(rootDirectory: root)
  let receipt = try harness.prepare(
    VaporizeKuraWorldSeedStateSpec(
      worldSlug: "operator review",
      worldTitle: "Operator review simulated world",
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

  #expect(receipt.storageFamily == "kura")
  #expect(receiptText.contains("turso") == false)
  #expect(receiptText.contains("libsql") == false)
  #expect(receiptText.contains("databaseURL") == false)
}

@Test("CUJ-21 Kura world seed-state receipts round-trip through Codable")
func kuraWorldSeedStateReceiptRoundTrips() throws {
  let receipt = VaporizeKuraWorldSeedStateReceipt(
    schemaVersion: "0.1.0",
    harnessKind: "kura-world-seed-state-harness",
    storageFamily: "kura",
    worldSlug: "round-trip",
    rootPath: "/tmp/root",
    cujManifestPath: "/tmp/root/cujs.json",
    seedStatePath: "/tmp/root/kura-world.seed-state.json",
    receiptPath: "/tmp/root/kura-world.seed-state.receipt.json",
    cujCount: 2,
    seedRecordCount: 2,
    sourceKind: "critical-user-journey",
    metadata: ["lane": "unit-test"],
    createdAt: "1970-01-01T00:00:00Z"
  )

  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(VaporizeKuraWorldSeedStateReceipt.self, from: data)

  #expect(decoded == receipt)
}
