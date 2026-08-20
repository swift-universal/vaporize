import Foundation
@_exported import TestFixtureLifecycle
@_exported import TestServiceAdoptionPolicy

public enum VaporizeTestServicePolicy {
  public static let policy = TestServiceAdoptionPolicy(
    version: "0.0.1",
    requiredDirectServiceModules: ["VaporizeTestSupport"],
    requiredServiceCartridges: [
      TestServiceCartridge(
        id: "test-fixture-lifecycle",
        packageName: "common-test-fixture-lifecycle",
        productName: "TestFixtureLifecycle",
        activation: "swift-testing-test-scoping-trait"
      ),
    ]
  )

  public static func audit(
    declarations: [TestTargetServiceDeclaration],
    legacyExceptions: [TestServiceLegacyException] = [],
    now: Date = Date()
  ) -> TestServiceAdoptionAudit {
    TestServiceAdoptionGate.audit(
      declarations: declarations,
      policy: policy,
      legacyExceptions: legacyExceptions,
      now: now
    )
  }
}
