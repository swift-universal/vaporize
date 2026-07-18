import Foundation
import SwiftCLIInstaller
import SwiftCLIUpdater

/// `vaporize self-update --product <name>`: update ANY installed CLI in
/// `~/.swiftpm/bin` from its signed appcast, generalizing the old
/// vaporize-updates-itself verb.
///
/// Flow: resolve `~/.swiftpm/bin/<product>` + its `<product>.metadata/Info.plist`
/// sidecar (SUFeedURL / SUPublicEDKey / CFBundleShortVersionString, written by
/// SwiftCLIInstaller) → fetch the appcast → SemanticVersion compare → if newer,
/// download + EdDSA-verify + atomically install via SwiftCLIUpdater's step
/// functions. Deliberately NO execv re-exec — vaporize is updating another
/// tool, not itself.
///
/// Refusal posture is LOUD and typed: missing binary, missing sidecar,
/// incomplete identity, unreachable feed, missing signature, and bad signature
/// each throw a typed error. An explicit self-update invocation fails loudly on
/// an unreachable feed (unlike the install gate's warn-and-proceed offline
/// posture) — the caller asked for an update and must never believe one
/// happened when it did not.
enum ProductSelfUpdate {
  // MARK: - Pure decision (unit-tested with injected fixtures)

  enum Decision: Equatable {
    /// Feed's newest is not strictly newer than the installed version
    /// (`newest` is nil when the feed has no items).
    case upToDate(installed: String, newest: String?)
    /// Feed carries a strictly newer item; `newestVersion` is the resolved
    /// comparison version (shortVersionString preferred over sparkle:version).
    case update(item: AppcastItem, newestVersion: String)
  }

  /// Compare the sidecar-recorded installed version against the feed's newest
  /// item. Prefers `sparkle:shortVersionString` (the marketing version the
  /// sidecar records) and falls back to `sparkle:version` for CLI feeds that
  /// publish the semantic version there.
  static func decide(installedVersion: String, feed: AppcastFeed) -> Decision {
    guard let newest = feed.newest else {
      return .upToDate(installed: installedVersion, newest: nil)
    }
    let newestVersion = newest.shortVersion ?? newest.version
    if SemanticVersion(newestVersion) > SemanticVersion(installedVersion) {
      return .update(item: newest, newestVersion: newestVersion)
    }
    return .upToDate(installed: installedVersion, newest: newestVersion)
  }

  // MARK: - Runtime

  enum Outcome: Equatable {
    case upToDate(installed: String, newest: String?)
    case updated(from: String, to: String, installedPath: String)
  }

  /// Run the whole update for one installed product. `session` may serve
  /// file:// URLs, so the full path is provable offline.
  @discardableResult
  static func run(
    product: String,
    binDirectory: URL,
    session: URLSession = .shared,
    log: (String) -> Void = { print($0) }
  ) async throws -> Outcome {
    let installedPath = binDirectory.appendingPathComponent(product).path
    guard FileManager.default.isExecutableFile(atPath: installedPath) else {
      throw ProductSelfUpdateError.productNotInstalled(
        product: product, expectedPath: installedPath)
    }

    // Typed, loud: missing sidecar and corrupt sidecar are distinct
    // InstalledProductSidecarError cases; both refuse the update.
    let sidecar = try InstalledProductSidecar.read(product: product, binDirectory: binDirectory)
    let identity = try sidecar.requireSelfUpdateIdentity()

    let config = SparkleConfig(
      productName: product,
      feedURL: identity.feedURL,
      publicEDKeyBase64: identity.publicEDKeyBase64,
      currentVersion: identity.installedVersion,
      installedBinaryPath: installedPath
    )

    let feedData: Data
    do {
      let (data, response) = try await session.data(from: identity.feedURL)
      if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        throw UpdaterError.feedHTTPStatus(http.statusCode)
      }
      feedData = data
    } catch {
      throw ProductSelfUpdateError.feedUnreachable(
        product: product,
        feedURL: identity.feedURL.absoluteString,
        detail: error.localizedDescription
      )
    }
    let feed = try AppcastFeed.parse(feedData)

    switch decide(installedVersion: identity.installedVersion, feed: feed) {
    case .upToDate(let installed, let newest):
      log(
        "vaporize: [\(product)] up to date — installed \(installed), feed newest \(newest ?? "<no items>")."
      )
      return .upToDate(installed: installed, newest: newest)

    case .update(let item, let newestVersion):
      log(
        "vaporize: [\(product)] installed \(identity.installedVersion) is behind \(newestVersion) — downloading \(item.enclosureURL?.absoluteString ?? "<no enclosure>")"
      )
      let enclosure = try await SelfUpdater.downloadEnclosure(item: item, session: session)
      do {
        // Missing signature and invalid signature both throw typed
        // UpdaterError values; never install unverified bytes.
        try SelfUpdater.verify(item: item, data: enclosure, config: config)
      } catch {
        throw ProductSelfUpdateError.refused(
          product: product,
          version: newestVersion,
          detail: error.localizedDescription
        )
      }
      try SelfUpdater.installReplacing(enclosureData: enclosure, item: item, config: config)
      // Track the swap in the sidecar so the recorded version matches the
      // installed bytes (and the next check does not re-download forever).
      try InstalledProductSidecar.updateShortVersion(
        product: product, binDirectory: binDirectory, to: newestVersion)
      log(
        "vaporize: [\(product)] updated \(identity.installedVersion) -> \(newestVersion) at \(installedPath) (sidecar version recorded)."
      )
      return .updated(
        from: identity.installedVersion, to: newestVersion, installedPath: installedPath)
    }
  }
}

enum ProductSelfUpdateError: Error, Equatable, CustomStringConvertible {
  case productNotInstalled(product: String, expectedPath: String)
  case feedUnreachable(product: String, feedURL: String, detail: String)
  case refused(product: String, version: String, detail: String)

  var description: String {
    switch self {
    case .productNotInstalled(let product, let expectedPath):
      return "self-update: no installed executable for `\(product)` at \(expectedPath)."
    case .feedUnreachable(let product, let feedURL, let detail):
      return "self-update: [\(product)] appcast \(feedURL) unreachable — no update performed. "
        + detail
    case .refused(let product, let version, let detail):
      return "self-update: [\(product)] REFUSED update to \(version) — installed binary unchanged. "
        + detail
    }
  }
}
