import Foundation
import Testing
import VaporizeTestSupport

@Test(.fixtureLifecycle("vaporize-test-service-adoption"))
func coreTestServicePrimeExampleProvidesAnIsolatedSession() throws {
  let session = try #require(TestFixtureLifecycle.current)
  let fixture = try session.writeMockText("fixture only", named: "prime-example.txt")

  #expect(fixture.deletingLastPathComponent() == session.rootURL)
  #expect(FileManager.default.fileExists(atPath: fixture.path))
}

@Test("cuj-32 all Vaporize test targets compose the Core test service")
func allVaporizeTestTargetsComposeTheCoreTestService() throws {
  let packageManifestURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Package.swift")
  let manifest = try String(contentsOf: packageManifestURL, encoding: .utf8)
  let declarations = SwiftPMTestTargetManifestScanner.scan(
    packageManifest: manifest,
    requiredServiceModules: VaporizeTestServicePolicy.policy.requiredDirectServiceModules
  )
  let audit = VaporizeTestServicePolicy.audit(declarations: declarations)

  #expect(VaporizeTestServicePolicy.policy.requiredServiceCartridges.map(\.id) == [
    "test-fixture-lifecycle",
  ])
  #expect(declarations.count >= 30)
  #expect(audit.status == "pass")
  #expect(audit.waivedTargetNames.isEmpty)
  #expect(audit.missingTargetNames.isEmpty)
  #expect(audit.expiredExceptionTargetNames.isEmpty)
}

@Test("cuj-32 the adoption gate exposes missing and expired migration work")
func adoptionGateExposesMissingAndExpiredMigrationWork() {
  let declarations = [
    TestTargetServiceDeclaration(
      targetName: "AdoptedTests",
      directServiceModules: ["VaporizeTestSupport"]
    ),
    TestTargetServiceDeclaration(targetName: "LegacyTests", directServiceModules: []),
    TestTargetServiceDeclaration(targetName: "ExpiredTests", directServiceModules: []),
  ]
  let now = Date(timeIntervalSince1970: 100)
  let audit = VaporizeTestServicePolicy.audit(
    declarations: declarations,
    legacyExceptions: [
      TestServiceLegacyException(
        targetName: "LegacyTests",
        owner: "legacy-test-owner",
        reason: "migration tracked separately",
        expiresAt: Date(timeIntervalSince1970: 200)
      ),
      TestServiceLegacyException(
        targetName: "ExpiredTests",
        owner: "legacy-test-owner",
        reason: "migration deadline elapsed",
        expiresAt: Date(timeIntervalSince1970: 99)
      ),
    ],
    now: now
  )

  #expect(audit.status == "fail")
  #expect(audit.adoptedTargetNames == ["AdoptedTests"])
  #expect(audit.waivedTargetNames == ["LegacyTests"])
  #expect(audit.expiredExceptionTargetNames == ["ExpiredTests"])
}
