import Foundation
import Testing

@testable import VaporizeCLI

@Suite("Maintainer SwiftPM authority")
struct MaintainerSwiftPMAuthorityTests {
  @Test("registry materializes deterministic file mirrors for maintainer checkouts")
  func registryMaterializesDeterministicFileMirrors() throws {
    let fixture = try MaintainerAuthorityFixture(
      authorities: [
        .init(identity: "swift-log"),
        .init(identity: "swift-async-algorithms"),
      ]
    )
    defer { fixture.remove() }

    let resolvedConfigurationPath = try MaintainerSwiftPMConfiguration.resolve(
      explicitPath: nil,
      packagePath: fixture.package.path
    )
    let configurationPath = try #require(resolvedConfigurationPath)
    defer { try? FileManager.default.removeItem(atPath: configurationPath) }

    let mirrorFile = URL(fileURLWithPath: configurationPath)
      .appendingPathComponent("mirrors.json")
    let document = try JSONDecoder().decode(
      MirrorDocument.self,
      from: Data(contentsOf: mirrorFile)
    )

    #expect(document.version == 1)
    #expect(
      document.object.map(\.original) == [
        "https://github.com/apple/swift-async-algorithms",
        "https://github.com/apple/swift-async-algorithms.git",
        "https://github.com/apple/swift-log",
        "https://github.com/apple/swift-log.git",
      ]
    )
    #expect(
      document.object.allSatisfy {
        $0.mirror.hasPrefix(fixture.substrate.standardizedFileURL.absoluteString)
      }
    )
  }

  @Test("pins and workspace state select the complete maintainer authority closure")
  func pinsAndWorkspaceSelectCompleteAuthorityClosure() throws {
    let fixture = try MaintainerAuthorityFixture(
      authorities: [
        .init(identity: "swift-log"),
        .init(identity: "swift-collections"),
        .init(identity: "swift-async-algorithms"),
      ]
    )
    defer { fixture.remove() }

    try fixture.writeResolvedPins([
      "swift-log",
      "swift-async-algorithms",
    ])
    try fixture.writeWorkspaceDependencies([
      .init(
        identity: "swift-collections",
        kind: "fileSystem",
        location: fixture.checkout(for: "swift-collections").absoluteString,
        state: "fileSystem",
        path: nil
      )
    ])

    let dependencies = try MaintainerSwiftPMConfiguration.editableDependencies(
      packagePath: fixture.package.path
    )

    #expect(
      dependencies.map(\.identity) == [
        "swift-async-algorithms",
        "swift-collections",
        "swift-log",
      ]
    )
    #expect(dependencies.map(\.requiresEdit) == [true, false, true])
    #expect(
      dependencies.map(\.checkoutPath) == [
        fixture.checkout(for: "swift-async-algorithms").path,
        fixture.checkout(for: "swift-collections").path,
        fixture.checkout(for: "swift-log").path,
      ]
    )
  }

  @Test("conflicting editable checkout is rejected instead of silently overridden")
  func conflictingEditableCheckoutIsRejected() throws {
    let fixture = try MaintainerAuthorityFixture(
      authorities: [.init(identity: "swift-log")]
    )
    defer { fixture.remove() }

    let conflictingPath = fixture.root.appendingPathComponent("other-swift-log").path
    try fixture.writeWorkspaceDependencies([
      .init(
        identity: "swift-log",
        kind: "remoteSourceControl",
        location: "https://github.com/apple/swift-log",
        state: "edited",
        path: conflictingPath
      )
    ])

    do {
      _ = try MaintainerSwiftPMConfiguration.editableDependencies(
        packagePath: fixture.package.path
      )
      Issue.record("Expected a conflicting editable checkout to be rejected.")
    } catch let error as MaintainerSwiftPMConfigurationError {
      guard case .conflictingEditableDependency(
        let identity,
        let expected,
        let actual
      ) = error
      else {
        Issue.record("Unexpected maintainer authority error: \(error)")
        return
      }
      #expect(identity == "swift-log")
      #expect(expected == fixture.checkout(for: "swift-log").path)
      #expect(actual == conflictingPath)
    }
  }

  @Test("duplicate registry identities are rejected")
  func duplicateRegistryIdentitiesAreRejected() throws {
    let fixture = try MaintainerAuthorityFixture(
      authorities: [
        .init(identity: "swift-log"),
        .init(identity: "swift-log"),
      ]
    )
    defer { fixture.remove() }
    try fixture.writeResolvedPins(["swift-log"])

    do {
      _ = try MaintainerSwiftPMConfiguration.editableDependencies(
        packagePath: fixture.package.path
      )
      Issue.record("Expected a duplicate authority identity to be rejected.")
    } catch let error as MaintainerSwiftPMConfigurationError {
      guard case .duplicateIdentity(let identity) = error else {
        Issue.record("Unexpected maintainer authority error: \(error)")
        return
      }
      #expect(identity == "swift-log")
    }
  }

  @Test("Package.resolved snapshot restores prior bytes and removes generated state")
  func packageResolutionSnapshotRestoresBothStates() throws {
    let fixture = try MaintainerAuthorityFixture(
      authorities: [.init(identity: "swift-log")]
    )
    defer { fixture.remove() }

    let resolution = fixture.package.appendingPathComponent("Package.resolved")
    let original = Data("{\"pins\":[{\"identity\":\"swift-log\"}]}\n".utf8)
    try original.write(to: resolution)
    let existingSnapshot = try PackageResolutionSnapshot.capture(
      packagePath: fixture.package.path
    )
    try Data("changed\n".utf8).write(to: resolution)
    try existingSnapshot.restore()
    #expect(try Data(contentsOf: resolution) == original)

    try FileManager.default.removeItem(at: resolution)
    let absentSnapshot = try PackageResolutionSnapshot.capture(
      packagePath: fixture.package.path
    )
    try Data("generated\n".utf8).write(to: resolution)
    try absentSnapshot.restore()
    #expect(!FileManager.default.fileExists(atPath: resolution.path))
  }

  @Test("maintainer-dependencies parses as a productless typed receipt operation")
  func maintainerDependenciesParsesAsProductlessReceiptOperation() throws {
    let command = try VaporizeCLI.parse([
      "maintainer-dependencies",
      "--package-path", "/workspace/package",
      "--receipt-path", "/workspace/receipt.json",
    ])

    #expect(command.mode == .maintainerDependencies)
    #expect(command.packagePath == "/workspace/package")
    #expect(command.receiptPath == "/workspace/receipt.json")
    #expect(command.product == nil)
  }

  @Test("Swift Testing builds productless package arguments")
  func swiftTestingBuildsProductlessPackageArguments() throws {
    var arguments = ["test"]
    #if os(macOS)
      arguments.append("swift")
    #endif
    arguments += [
      "--package-path", "/workspace/package",
      "--configuration", "debug",
      "--",
      "--filter", "MaintainerSwiftPMAuthorityTests",
    ]
    let command = try VaporizeCLI.parse(arguments)

    #expect(command.mode == .test)
    #expect(command.product == nil)
    #expect(
      try command.swiftTestArguments() == [
        "test",
        "--package-path", "/workspace/package",
        "-c", "debug",
        "--filter", "MaintainerSwiftPMAuthorityTests",
      ]
    )
  }
}

private struct MaintainerAuthorityFixture {
  struct Authority {
    let identity: String

    var maintainerPath: String {
      "maintainers/apple/public/swift/\(identity)"
    }

    var originals: [String] {
      [
        "https://github.com/apple/\(identity)",
        "https://github.com/apple/\(identity).git",
      ]
    }
  }

  struct WorkspaceDependency {
    let identity: String
    let kind: String
    let location: String
    let state: String
    let path: String?
  }

  let root: URL
  let substrate: URL
  let package: URL

  init(authorities: [Authority]) throws {
    root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "vaporize-maintainer-authority-\(UUID().uuidString)",
      isDirectory: true
    )
    substrate = root.appendingPathComponent("substrate", isDirectory: true)
    package = substrate.appendingPathComponent(
      "collectives/example/private/universal/domain/tooling/spm/example",
      isDirectory: true
    )

    try FileManager.default.createDirectory(
      at: package,
      withIntermediateDirectories: true
    )
    try Data("// swift-tools-version: 6.4\n".utf8).write(
      to: package.appendingPathComponent("Package.swift")
    )

    for authority in authorities {
      let checkout = substrate.appendingPathComponent(
        authority.maintainerPath,
        isDirectory: true
      )
      try FileManager.default.createDirectory(
        at: checkout,
        withIntermediateDirectories: true
      )
      try Data("// swift-tools-version: 6.4\n".utf8).write(
        to: checkout.appendingPathComponent("Package.swift")
      )
    }

    let registry: [String: Any] = [
      "schemaVersion": "0.1.0",
      "authorities": authorities.map {
        [
          "identity": $0.identity,
          "maintainerPath": $0.maintainerPath,
          "originals": $0.originals,
        ]
      },
    ]
    let registryURL = substrate.appendingPathComponent(
      "maintainers/swiftpm-authorities.json"
    )
    try FileManager.default.createDirectory(
      at: registryURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try JSONSerialization.data(withJSONObject: registry, options: [.sortedKeys])
      .write(to: registryURL)
  }

  func checkout(for identity: String) -> URL {
    substrate.appendingPathComponent(
      "maintainers/apple/public/swift/\(identity)",
      isDirectory: true
    ).standardizedFileURL
  }

  func writeResolvedPins(_ identities: [String]) throws {
    let document: [String: Any] = [
      "pins": identities.map { ["identity": $0] },
    ]
    try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
      .write(to: package.appendingPathComponent("Package.resolved"))
  }

  func writeWorkspaceDependencies(_ dependencies: [WorkspaceDependency]) throws {
    let document: [String: Any] = [
      "object": [
        "dependencies": dependencies.map { dependency in
          [
            "packageRef": [
              "identity": dependency.identity,
              "kind": dependency.kind,
              "location": dependency.location,
            ],
            "state": [
              "name": dependency.state,
              "path": dependency.path.map { $0 as Any } ?? NSNull(),
            ],
          ]
        },
      ],
    ]
    try FileManager.default.createDirectory(
      at: package.appendingPathComponent(".build", isDirectory: true),
      withIntermediateDirectories: true
    )
    try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
      .write(to: package.appendingPathComponent(".build/workspace-state.json"))
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}

private struct MirrorDocument: Decodable {
  struct Mirror: Decodable {
    let mirror: String
    let original: String
  }

  let object: [Mirror]
  let version: Int
}
