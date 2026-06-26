import Foundation
import Testing
import VaporizeTestSupport

@Test("CUJ-21 prepares an isolated local libSQL-style database fixture")
func preparesIsolatedLocalLibSQLFixture() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-21-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: root) }

  let harness = VaporizeDatabaseTestHarness(rootDirectory: root)
  let instance = try harness.prepare(
    VaporizeDatabaseHarnessSpec(
      identifier: "SCM audit test",
      storage: .localLibSQLFile(fileName: "audit.libsql"),
      migrations: [
        "create table vaporize_receipts(id text primary key, status text not null);",
      ],
      seedStatements: [
        "insert into vaporize_receipts(id, status) values ('git-savepoint-audit', 'passed');",
      ],
      metadata: [
        "productLine": "scm",
      ]
    ),
    createdAt: Date(timeIntervalSince1970: 0)
  )

  #expect(instance.harnessKind == "turso-like-database-test-harness")
  #expect(instance.storageMode == "local-libsql-file")
  #expect(instance.requiresNetwork == false)
  #expect(instance.databaseURL.hasPrefix("file://"))
  #expect(instance.migrationCount == 1)
  #expect(instance.seedStatementCount == 1)
  #expect(instance.metadata["productLine"] == "scm")
  #expect(instance.createdAt == "1970-01-01T00:00:00Z")

  let databasePath = try #require(URL(string: instance.databaseURL)?.path)
  #expect(FileManager.default.fileExists(atPath: databasePath))
  #expect(FileManager.default.fileExists(atPath: instance.migrationScriptPath))
  #expect(FileManager.default.fileExists(atPath: instance.seedScriptPath))
  #expect(FileManager.default.fileExists(atPath: instance.receiptPath))
}

@Test("CUJ-21 keeps remote Turso-style configuration network-free in tests")
func preparesRemoteTursoConfigurationWithoutNetworkAccess() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("vaporize-cuj-21-remote-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: root) }

  let harness = VaporizeDatabaseTestHarness(rootDirectory: root)
  let instance = try harness.prepare(
    VaporizeDatabaseHarnessSpec(
      identifier: "remote proof",
      storage: .remoteTursoLibSQL(
        databaseURL: "libsql://vaporize-test.turso.example",
        authTokenEnvironmentVariable: "TURSO_AUTH_TOKEN"
      ),
      migrations: [
        "create table proof(id text primary key);",
      ]
    )
  )

  #expect(instance.storageMode == "remote-turso-libsql")
  #expect(instance.requiresNetwork == true)
  #expect(instance.databaseURL == "libsql://vaporize-test.turso.example")
  #expect(FileManager.default.fileExists(atPath: instance.receiptPath))
}

@Test("CUJ-21 database harness receipts round-trip through Codable")
func databaseHarnessReceiptRoundTrips() throws {
  let receipt = VaporizeDatabaseHarnessInstance(
    schemaVersion: "0.1.0",
    harnessKind: "turso-like-database-test-harness",
    identifier: "round-trip",
    storageMode: "local-libsql-file",
    rootPath: "/tmp/root",
    databaseURL: "file:///tmp/root/database.libsql",
    migrationScriptPath: "/tmp/root/migrations.sql",
    seedScriptPath: "/tmp/root/seed.sql",
    receiptPath: "/tmp/root/database-harness-receipt.json",
    migrationCount: 2,
    seedStatementCount: 1,
    requiresNetwork: false,
    metadata: ["lane": "unit-test"],
    createdAt: "1970-01-01T00:00:00Z"
  )

  let data = try JSONEncoder().encode(receipt)
  let decoded = try JSONDecoder().decode(VaporizeDatabaseHarnessInstance.self, from: data)

  #expect(decoded == receipt)
}
