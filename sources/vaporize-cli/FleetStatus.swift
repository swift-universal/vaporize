import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import SwiftCLIInstaller
import SwiftCLIUpdater

/// `vaporize fleet-status`: the permanent mechanical answer to "how do we know
/// an installed tool is the latest?" — the Fleet Yard's data spine
/// (sparkle-campus design §3 Fleet Yard, §5 phase 1).
///
/// Scans an install bin directory (default `~/.swiftpm/bin`) for installed
/// products, reads each product's `<product>.metadata/Info.plist` sidecar via
/// SwiftCLIInstaller's ``InstalledProductSidecar`` API, fetches the recorded
/// appcast when one exists, and classifies every tool:
///
/// - `current` — installed version is not behind the feed's newest item
/// - `behind` — the feed carries a strictly newer item (latest recorded)
/// - `critical-behind` — the installed version violates the feed-declared
///   minimum: a `sparkle:criticalUpdate`-flagged item is newer than the
///   install (honoring since-version narrowing). Checked FIRST, before the
///   installable-newest compare, mirroring InstallVersionGate's hard lane.
/// - `unknown` — feed reachable + parseable but carries no comparable items
/// - `feed-unreachable` — the recorded SUFeedURL could not be fetched
/// - `feed-malformed` — fetched bytes are not a parseable appcast
/// - `no-sidecar` — installed executable with NO metadata sidecar at all;
///   absence of update identity is a finding, not a skip
/// - `no-update-identity` — sidecar exists but the self-update triple
///   (SUFeedURL / SUPublicEDKey / CFBundleShortVersionString) is incomplete
/// - `sidecar-error` — sidecar present but corrupt/unreadable; the typed
///   ``InstalledProductSidecarError`` is surfaced in the row, never swallowed
///
/// Per-row failures never abort the fleet scan: every degraded state is a
/// typed row status with the error detail on the record (always-loud).
enum FleetStatus {
  /// Stable, documented status vocabulary. Raw values are the JSON contract.
  enum Status: String, Codable, Sendable, Equatable {
    case current
    case behind
    case criticalBehind = "critical-behind"
    case unknown
    case feedUnreachable = "feed-unreachable"
    case feedMalformed = "feed-malformed"
    case noSidecar = "no-sidecar"
    case noUpdateIdentity = "no-update-identity"
    case sidecarError = "sidecar-error"
  }

  /// One installed tool's fleet row. Field names are the stable JSON contract:
  /// `product` (executable name), `installedVersion` (sidecar
  /// CFBundleShortVersionString, null when unrecorded), `installedBuild`
  /// (sidecar CFBundleVersion, null when unrecorded), `feedURL` (sidecar
  /// SUFeedURL as stored, null when unrecorded), `latestVersion` (feed's
  /// newest comparable version, null when no feed answer), `status` (see
  /// ``Status``), `detail` (human-readable finding or typed error text, null
  /// when the row needs no explanation).
  struct Row: Codable, Sendable, Equatable {
    var product: String
    var installedVersion: String?
    var installedBuild: String? = nil
    var feedURL: String?
    var latestVersion: String?
    var status: Status
    var detail: String?
  }

  /// Per-status row counts. Field names are the stable JSON contract.
  struct Summary: Codable, Sendable, Equatable {
    var total: Int
    var current: Int
    var behind: Int
    var criticalBehind: Int
    var unknown: Int
    var feedUnreachable: Int
    var feedMalformed: Int
    var noSidecar: Int
    var noUpdateIdentity: Int
    var sidecarError: Int

    init(rows: [Row]) {
      total = rows.count
      current = rows.count { $0.status == .current }
      behind = rows.count { $0.status == .behind }
      criticalBehind = rows.count { $0.status == .criticalBehind }
      unknown = rows.count { $0.status == .unknown }
      feedUnreachable = rows.count { $0.status == .feedUnreachable }
      feedMalformed = rows.count { $0.status == .feedMalformed }
      noSidecar = rows.count { $0.status == .noSidecar }
      noUpdateIdentity = rows.count { $0.status == .noUpdateIdentity }
      sidecarError = rows.count { $0.status == .sidecarError }
    }
  }

  /// The typed fleet-status report. Field names are the stable JSON contract:
  /// `binDirectory` (absolute scanned path), `tools` (one ``Row`` per
  /// installed executable, sorted by product name), `summary` (``Summary``).
  struct Report: Codable, Sendable, Equatable {
    var binDirectory: String
    var tools: [Row]
    var summary: Summary

    init(binDirectory: String, tools: [Row]) {
      self.binDirectory = binDirectory
      self.tools = tools
      summary = Summary(rows: tools)
    }
  }

  // MARK: - Scan

  /// Installed products = executable regular files directly in the bin
  /// directory (metadata sidecars are `<product>.metadata/` DIRECTORIES and
  /// the domain publish tree is `domain/`; directories are never products).
  /// A missing/unreadable bin directory throws loudly — an empty fleet and an
  /// unscannable path are never conflated.
  static func scanProducts(binDirectory: URL) throws -> [String] {
    let fm = FileManager.default
    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: binDirectory.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      throw FleetStatusError.binDirectoryMissing(path: binDirectory.path)
    }
    let entries: [String]
    do {
      entries = try fm.contentsOfDirectory(atPath: binDirectory.path)
    } catch {
      throw FleetStatusError.binDirectoryUnreadable(
        path: binDirectory.path, detail: String(describing: error))
    }
    return
      entries
      .filter { !$0.hasPrefix(".") }
      .filter { entry in
        let path = binDirectory.appendingPathComponent(entry).path
        var entryIsDirectory: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &entryIsDirectory),
          !entryIsDirectory.boolValue
        else { return false }
        return fm.isExecutableFile(atPath: path)
      }
      .sorted()
  }

  // MARK: - Per-tool classification

  /// Classify one installed product. Never throws: every degraded state is a
  /// typed row status carrying the error detail.
  static func row(
    product: String,
    binDirectory: URL,
    session: URLSession = .shared
  ) async -> Row {
    // Sidecar: genuine absence is nil; corruption throws typed — surfaced.
    let sidecar: InstalledProductSidecar
    do {
      guard
        let present = try InstalledProductSidecar.readIfPresent(
          product: product, binDirectory: binDirectory)
      else {
        return Row(
          product: product,
          status: .noSidecar,
          detail:
            "No metadata sidecar — no update identity recorded. "
            + "Reinstall with --su-feed-url/--su-public-ed-key and --product-version to record one."
        )
      }
      sidecar = present
    } catch {
      return Row(
        product: product,
        status: .sidecarError,
        detail: String(describing: error)
      )
    }
    let installedBuild = sidecar.payload["CFBundleVersion"]

    // Identity: incomplete triples are a typed finding, not a crash.
    let identity: (feedURL: URL, publicEDKeyBase64: String, installedVersion: String)
    do {
      identity = try sidecar.requireSelfUpdateIdentity()
    } catch {
      return Row(
        product: product,
        installedVersion: sidecar.shortVersionString,
        installedBuild: installedBuild,
        feedURL: sidecar.feedURLString,
        status: .noUpdateIdentity,
        detail: String(describing: error)
      )
    }

    // Feed fetch (file:// URLs work, so the whole path is provable offline).
    let feedData: Data
    do {
      let (data, response) = try await session.data(from: identity.feedURL)
      if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        throw UpdaterError.feedHTTPStatus(http.statusCode)
      }
      feedData = data
    } catch {
      return Row(
        product: product,
        installedVersion: identity.installedVersion,
        installedBuild: installedBuild,
        feedURL: identity.feedURL.absoluteString,
        status: .feedUnreachable,
        detail: error.localizedDescription
      )
    }

    let feed: AppcastFeed
    do {
      feed = try AppcastFeed.parse(feedData)
    } catch {
      return Row(
        product: product,
        installedVersion: identity.installedVersion,
        installedBuild: installedBuild,
        feedURL: identity.feedURL.absoluteString,
        status: .feedMalformed,
        detail: error.localizedDescription
      )
    }

    // HARD lane first, BEFORE the installable-newest compare (mirroring
    // InstallVersionGate): an install below the feed-declared minimum — the
    // newest `sparkle:criticalUpdate`-flagged item, since-version honored —
    // is critical-behind even when no newer installable enclosure exists
    // (the informational kill-switch shape).
    if let critical = feed.newestCritical,
      SemanticVersion(identity.installedVersion) < SemanticVersion(critical.version),
      critical.isCritical(comparedToInstalled: identity.installedVersion)
    {
      let newestInstallable = feed.newest.map { $0.shortVersion ?? $0.version }
      return Row(
        product: product,
        installedVersion: identity.installedVersion,
        installedBuild: installedBuild,
        feedURL: identity.feedURL.absoluteString,
        latestVersion: newestInstallable ?? critical.version,
        status: .criticalBehind,
        detail:
          "CRITICAL: installed \(identity.installedVersion) is below the feed-declared minimum "
          + "\(critical.version) — update is mandatory: "
          + "`vaporize self-update --product \(product)`"
      )
    }

    // Same comparison the self-update verb trusts — lifted, not re-derived.
    switch ProductSelfUpdate.decide(installedVersion: identity.installedVersion, feed: feed) {
    case .upToDate(let installed, let newest):
      guard let newest else {
        return Row(
          product: product,
          installedVersion: installed,
          installedBuild: installedBuild,
          feedURL: identity.feedURL.absoluteString,
          status: .unknown,
          detail: "Feed is reachable but carries no comparable items."
        )
      }
      return Row(
        product: product,
        installedVersion: installed,
        installedBuild: installedBuild,
        feedURL: identity.feedURL.absoluteString,
        latestVersion: newest,
        status: .current
      )
    case .update(_, let newestVersion):
      return Row(
        product: product,
        installedVersion: identity.installedVersion,
        installedBuild: installedBuild,
        feedURL: identity.feedURL.absoluteString,
        latestVersion: newestVersion,
        status: .behind,
        detail:
          "Update available: `vaporize self-update --product \(product)`"
      )
    }
  }

  // MARK: - Report

  static func report(
    binDirectory: URL,
    session: URLSession = .shared
  ) async throws -> Report {
    let products = try scanProducts(binDirectory: binDirectory)
    var rows: [Row] = []
    for product in products {
      rows.append(await row(product: product, binDirectory: binDirectory, session: session))
    }
    return Report(binDirectory: binDirectory.standardizedFileURL.path, tools: rows)
  }

  // MARK: - Text rendering

  /// Aligned text table. Rows with a detail carry it on an indented
  /// continuation line so column alignment survives long typed errors.
  static func renderTable(_ report: Report) -> String {
    let header = ["PRODUCT", "INSTALLED", "BUILD", "LATEST", "STATUS"]
    let cells: [[String]] = report.tools.map { row in
      [
        row.product,
        row.installedVersion ?? "-",
        row.installedBuild ?? "-",
        row.latestVersion ?? "-",
        row.status.rawValue,
      ]
    }
    let widths: [Int] = (0..<header.count).map { column in
      max(header[column].count, cells.map { $0[column].count }.max() ?? 0)
    }
    func line(_ values: [String]) -> String {
      values.enumerated()
        .map { $0.offset == values.count - 1 ? $0.element : $0.element.padded(to: widths[$0.offset]) }
        .joined(separator: "  ")
    }
    var lines: [String] = []
    let summary = report.summary
    lines.append(
      "fleet-status: \(report.binDirectory) tools=\(summary.total) "
        + "current=\(summary.current) behind=\(summary.behind) "
        + "critical-behind=\(summary.criticalBehind) unknown=\(summary.unknown) "
        + "feed-unreachable=\(summary.feedUnreachable) feed-malformed=\(summary.feedMalformed) "
        + "no-sidecar=\(summary.noSidecar) no-update-identity=\(summary.noUpdateIdentity) "
        + "sidecar-error=\(summary.sidecarError)"
    )
    lines.append(line(header))
    for (row, rendered) in zip(report.tools, cells) {
      lines.append(line(rendered))
      if let detail = row.detail {
        lines.append("    ! \(detail)")
      }
    }
    return lines.joined(separator: "\n")
  }
}

enum FleetStatusError: Error, Equatable, CustomStringConvertible {
  case binDirectoryMissing(path: String)
  case binDirectoryUnreadable(path: String, detail: String)

  var description: String {
    switch self {
    case .binDirectoryMissing(let path):
      return "fleet-status: bin directory does not exist: \(path)"
    case .binDirectoryUnreadable(let path, let detail):
      return "fleet-status: bin directory could not be read: \(path) — \(detail)"
    }
  }
}

extension String {
  fileprivate func padded(to width: Int) -> String {
    count >= width ? self : self + String(repeating: " ", count: width - count)
  }
}
