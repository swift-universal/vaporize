import ArgumentParser
import CryptoKit
import Foundation
import SwiftCLIInstaller
import SwiftCLIUpdater
import Testing

@testable import VaporizeCLI

// MARK: - Fixture helpers (all offline: file:// URLs, no network)

private let fixtureProduct = "fixture.cli@cuj29.clia.sh"

private struct UpdateFixture {
  let binDirectory: URL
  let installedPath: String
  let feedURL: URL
  let enclosureURL: URL
  let privateKey: Curve25519.Signing.PrivateKey
  let publicKeyBase64: String
  let v2Bytes: Data

  func installedBytes() throws -> Data {
    try Data(contentsOf: URL(fileURLWithPath: installedPath))
  }

  func sidecarVersion() throws -> String? {
    try InstalledProductSidecar.read(product: fixtureProduct, binDirectory: binDirectory)
      .shortVersionString
  }
}

/// Lay out a complete offline update world in a temp directory: an "installed"
/// v1 binary, its metadata sidecar, a raw v2 enclosure, and a signed appcast —
/// then hand back the knobs the negative tests need to sabotage it.
private func makeUpdateFixture(
  installedVersion: String = "1.0.0",
  feedVersion: String = "2.0.0",
  signWithWrongKey: Bool = false,
  omitSignature: Bool = false,
  sidecarPublicKeyOverride: String? = nil
) throws -> UpdateFixture {
  let fm = FileManager.default
  let root = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("vaporize-cuj29-\(UUID().uuidString)", isDirectory: true)
  let bin = root.appendingPathComponent("bin", isDirectory: true)
  let serve = root.appendingPathComponent("serve", isDirectory: true)
  try fm.createDirectory(at: bin, withIntermediateDirectories: true)
  try fm.createDirectory(at: serve, withIntermediateDirectories: true)

  // The "installed" v1 binary (bytes are what matters; content is arbitrary).
  let installed = bin.appendingPathComponent(fixtureProduct)
  try Data("#!/bin/sh\necho fixture-v1\n".utf8).write(to: installed)
  try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installed.path)

  // The v2 enclosure: raw (non-zip) executable bytes, Sparkle-signed.
  let v2Bytes = Data("#!/bin/sh\necho fixture-v2\n".utf8)
  let enclosureURL = serve.appendingPathComponent("enclosure.bin")
  try v2Bytes.write(to: enclosureURL)

  let signingKey = Curve25519.Signing.PrivateKey()
  let wrongKey = Curve25519.Signing.PrivateKey()
  let signature = try (signWithWrongKey ? wrongKey : signingKey)
    .signature(for: v2Bytes).base64EncodedString()
  let signatureAttribute = omitSignature ? "" : " sparkle:edSignature=\"\(signature)\""

  let feedURL = serve.appendingPathComponent("appcast.xml")
  try Data(
    """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <title>\(fixtureProduct)</title>
        <item>
          <title>\(feedVersion)</title>
          <enclosure url="\(enclosureURL.absoluteString)"
                     sparkle:version="\(feedVersion)"\(signatureAttribute)
                     length="\(v2Bytes.count)"
                     type="application/octet-stream"/>
        </item>
      </channel>
    </rss>
    """.utf8
  ).write(to: feedURL)

  // The metadata sidecar, exactly where SwiftCLIInstaller writes it.
  let publicKeyBase64 = signingKey.publicKey.rawRepresentation.base64EncodedString()
  let sidecarDirectory = bin.appendingPathComponent(
    "\(fixtureProduct).metadata", isDirectory: true)
  try fm.createDirectory(at: sidecarDirectory, withIntermediateDirectories: true)
  let payload: [String: String] = [
    "CFBundleExecutable": fixtureProduct,
    "CFBundleShortVersionString": installedVersion,
    "SUFeedURL": feedURL.absoluteString,
    "SUPublicEDKey": sidecarPublicKeyOverride ?? publicKeyBase64,
  ]
  let plist = try PropertyListSerialization.data(
    fromPropertyList: payload, format: .xml, options: 0)
  try plist.write(to: sidecarDirectory.appendingPathComponent("Info.plist"))

  return UpdateFixture(
    binDirectory: bin,
    installedPath: installed.path,
    feedURL: feedURL,
    enclosureURL: enclosureURL,
    privateKey: signingKey,
    publicKeyBase64: publicKeyBase64,
    v2Bytes: v2Bytes
  )
}

// MARK: - CLI surface

@Test("CUJ-29 parses the generalized self-update verb with --product")
func parsesSelfUpdateWithProduct() throws {
  let command = try VaporizeCLI.parse([
    "self-update",
    "--product",
    "roster.cli@kura-org.clia.sh",
  ])
  #expect(command.mode == .selfUpdate)
  #expect(command.product == "roster.cli@kura-org.clia.sh")
}

@Test("CUJ-29 parses install-time self-update identity flags")
func parsesInstallIdentityFlags() throws {
  let command = try VaporizeCLI.parse(coreInstallArguments([
    "--package-path", "/workspace/tool",
    "--product", "tool.cli@org.clia.sh",
    "--su-feed-url", "https://vapor-wares.pages.dev/appcast/tool.xml",
    "--su-public-ed-key", "AAAA",
  ]))
  let identity = try #require(try command.resolvedSelfUpdateIdentity())
  #expect(identity.feedURL.absoluteString == "https://vapor-wares.pages.dev/appcast/tool.xml")
  #expect(identity.publicEDKeyBase64 == "AAAA")
}

@Test("CUJ-29 a lone identity flag is a loud error; neither flag is a nil no-op")
func identityFlagsAreBothOrNeither() throws {
  let neither = try VaporizeCLI.parse(coreInstallArguments([
    "--package-path", "/w", "--product", "t.cli@o.clia.sh",
  ]))
  #expect(try neither.resolvedSelfUpdateIdentity() == nil)

  let lone = try VaporizeCLI.parse(coreInstallArguments([
    "--package-path", "/w", "--product", "t.cli@o.clia.sh",
    "--su-feed-url", "https://example.com/appcast.xml",
  ]))
  #expect(throws: (any Error).self) {
    _ = try lone.resolvedSelfUpdateIdentity()
  }
}

// MARK: - Pure decision (injected fixtures)

@Test("CUJ-29 decide: behind the feed selects the newest item")
func decideBehind() {
  let item = AppcastItem(
    version: "2.0.0", enclosureURL: URL(string: "https://example.com/e.zip")!)
  let decision = ProductSelfUpdate.decide(
    installedVersion: "1.0.0", feed: AppcastFeed(items: [item]))
  #expect(decision == .update(item: item, newestVersion: "2.0.0"))
}

@Test("CUJ-29 decide: current or ahead of the feed is upToDate")
func decideCurrentOrAhead() {
  let item = AppcastItem(
    version: "2.0.0", enclosureURL: URL(string: "https://example.com/e.zip")!)
  #expect(
    ProductSelfUpdate.decide(installedVersion: "2.0.0", feed: AppcastFeed(items: [item]))
      == .upToDate(installed: "2.0.0", newest: "2.0.0"))
  #expect(
    ProductSelfUpdate.decide(installedVersion: "3.0.0", feed: AppcastFeed(items: [item]))
      == .upToDate(installed: "3.0.0", newest: "2.0.0"))
}

@Test("CUJ-29 decide: empty feed is upToDate with no newest, never an update")
func decideEmptyFeed() {
  #expect(
    ProductSelfUpdate.decide(installedVersion: "1.0.0", feed: AppcastFeed(items: []))
      == .upToDate(installed: "1.0.0", newest: nil))
}

@Test("CUJ-29 decide: shortVersionString wins over build-number sparkle:version")
func decideShortVersionWins() {
  // App-world shape: sparkle:version is a build counter (2), short is 1.0.1.
  let item = AppcastItem(
    version: "2", shortVersion: "1.0.1",
    enclosureURL: URL(string: "https://example.com/e.zip")!)
  #expect(
    ProductSelfUpdate.decide(installedVersion: "1.0.1", feed: AppcastFeed(items: [item]))
      == .upToDate(installed: "1.0.1", newest: "1.0.1"))
}

// MARK: - Offline end-to-end through file:// URLs

@Test("CUJ-29 run: a signed newer enclosure atomically swaps the installed bytes and records the version")
func runSwapsBytesAndRecordsVersion() async throws {
  let fixture = try makeUpdateFixture()
  defer { try? FileManager.default.removeItem(at: fixture.binDirectory.deletingLastPathComponent()) }

  let outcome = try await ProductSelfUpdate.run(
    product: fixtureProduct,
    binDirectory: fixture.binDirectory,
    log: { _ in }
  )

  #expect(
    outcome
      == .updated(from: "1.0.0", to: "2.0.0", installedPath: fixture.installedPath))
  #expect(try fixture.installedBytes() == fixture.v2Bytes)
  #expect(try fixture.sidecarVersion() == "2.0.0")
  #expect(FileManager.default.isExecutableFile(atPath: fixture.installedPath))
}

@Test("CUJ-29 run: up to date performs no swap")
func runUpToDateIsNoOp() async throws {
  let fixture = try makeUpdateFixture(installedVersion: "2.0.0", feedVersion: "2.0.0")
  defer { try? FileManager.default.removeItem(at: fixture.binDirectory.deletingLastPathComponent()) }
  let before = try fixture.installedBytes()

  let outcome = try await ProductSelfUpdate.run(
    product: fixtureProduct, binDirectory: fixture.binDirectory, log: { _ in })

  #expect(outcome == .upToDate(installed: "2.0.0", newest: "2.0.0"))
  #expect(try fixture.installedBytes() == before)
}

// MARK: - Mandatory negatives: refusal paths

@Test("CUJ-29 negative: a wrong-key enclosure is REFUSED and the installed bytes are unchanged")
func wrongKeyEnclosureIsRefused() async throws {
  let fixture = try makeUpdateFixture(signWithWrongKey: true)
  defer { try? FileManager.default.removeItem(at: fixture.binDirectory.deletingLastPathComponent()) }
  let before = try fixture.installedBytes()

  await #expect(throws: ProductSelfUpdateError.self) {
    try await ProductSelfUpdate.run(
      product: fixtureProduct, binDirectory: fixture.binDirectory, log: { _ in })
  }
  #expect(try fixture.installedBytes() == before)
  #expect(try fixture.sidecarVersion() == "1.0.0")
}

@Test("CUJ-29 negative: an UNSIGNED enclosure is REFUSED, never installed")
func unsignedEnclosureIsRefused() async throws {
  let fixture = try makeUpdateFixture(omitSignature: true)
  defer { try? FileManager.default.removeItem(at: fixture.binDirectory.deletingLastPathComponent()) }
  let before = try fixture.installedBytes()

  do {
    _ = try await ProductSelfUpdate.run(
      product: fixtureProduct, binDirectory: fixture.binDirectory, log: { _ in })
    Issue.record("unsigned enclosure was not refused")
  } catch let error as ProductSelfUpdateError {
    guard case .refused(_, _, let detail) = error else {
      Issue.record("expected .refused, got \(error)")
      return
    }
    #expect(detail.contains("unsigned") || detail.contains("edSignature"))
  }
  #expect(try fixture.installedBytes() == before)
}

@Test("CUJ-29 negative: the refusal is the typed missing/invalid-signature error from SwiftCLIUpdater")
func verifyStepRefusesTampering() throws {
  let fixture = try makeUpdateFixture()
  defer { try? FileManager.default.removeItem(at: fixture.binDirectory.deletingLastPathComponent()) }
  let config = SparkleConfig(
    productName: fixtureProduct,
    feedURL: fixture.feedURL,
    publicEDKeyBase64: fixture.publicKeyBase64,
    currentVersion: "1.0.0",
    installedBinaryPath: fixture.installedPath)

  // Unsigned item -> missingSignature.
  let unsigned = AppcastItem(version: "2.0.0", enclosureURL: fixture.enclosureURL)
  #expect(throws: UpdaterError.missingSignature) {
    try SelfUpdater.verify(item: unsigned, data: fixture.v2Bytes, config: config)
  }

  // Wrong-key signature -> signatureInvalid.
  let wrongSignature = try Curve25519.Signing.PrivateKey()
    .signature(for: fixture.v2Bytes).base64EncodedString()
  let forged = AppcastItem(
    version: "2.0.0", enclosureURL: fixture.enclosureURL, edSignature: wrongSignature)
  #expect(throws: UpdaterError.signatureInvalid) {
    try SelfUpdater.verify(item: forged, data: fixture.v2Bytes, config: config)
  }
}

@Test("CUJ-29 negative: missing sidecar refuses with a typed error before any network use")
func missingSidecarRefuses() async throws {
  let fixture = try makeUpdateFixture()
  defer { try? FileManager.default.removeItem(at: fixture.binDirectory.deletingLastPathComponent()) }
  try FileManager.default.removeItem(
    at: fixture.binDirectory.appendingPathComponent(
      "\(fixtureProduct).metadata", isDirectory: true))

  await #expect(throws: InstalledProductSidecarError.self) {
    try await ProductSelfUpdate.run(
      product: fixtureProduct, binDirectory: fixture.binDirectory, log: { _ in })
  }
}

@Test("CUJ-29 negative: a product with no installed executable refuses loudly")
func missingBinaryRefuses() async throws {
  let fixture = try makeUpdateFixture()
  defer { try? FileManager.default.removeItem(at: fixture.binDirectory.deletingLastPathComponent()) }

  await #expect(throws: ProductSelfUpdateError.self) {
    try await ProductSelfUpdate.run(
      product: "ghost.cli@nowhere.clia.sh",
      binDirectory: fixture.binDirectory,
      log: { _ in })
  }
}

private func coreInstallArguments(_ arguments: [String]) -> [String] {
  #if os(macOS)
    ["install", "swift"] + arguments
  #else
    ["install"] + arguments
  #endif
}
