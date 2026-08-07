import ArgumentParser
import Foundation
import SwiftCLIInstaller
import SwiftCLIUpdater
import Testing

@testable import VaporizeCLI

// MARK: - Fixture helpers (all offline: file:// feeds, no network)

/// One fixture "installed tool" laid out exactly the way SwiftCLIInstaller
/// leaves it in a bin directory: the executable plus (optionally) its
/// `<product>.metadata/Info.plist` sidecar and a local file:// appcast.
private enum FixtureTool {
  /// Executable + sidecar + signed-shape appcast served from a file:// URL.
  case sidecared(product: String, installedVersion: String, feedVersion: String)
  /// Same as sidecared but the feed item carries `sparkle:criticalUpdate`.
  case criticallyBehind(product: String, installedVersion: String, feedVersion: String)
  /// Executable + sidecar whose SUFeedURL points at a nonexistent file.
  case unreachableFeed(product: String, installedVersion: String)
  /// Executable + a sidecar Info.plist that is NOT a valid property list.
  case corruptSidecar(product: String)
  /// Executable with no metadata sidecar at all.
  case bare(product: String)
}

private func makeFleetFixture(_ tools: [FixtureTool]) throws -> URL {
  let fm = FileManager.default
  let root = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("vaporize-cuj30-\(UUID().uuidString)", isDirectory: true)
  let bin = root.appendingPathComponent("bin", isDirectory: true)
  let serve = root.appendingPathComponent("serve", isDirectory: true)
  try fm.createDirectory(at: bin, withIntermediateDirectories: true)
  try fm.createDirectory(at: serve, withIntermediateDirectories: true)

  // A domain publish tree, like the real ~/.swiftpm/bin — directories are
  // never fleet products and must not appear as rows.
  try fm.createDirectory(
    at: bin.appendingPathComponent("domain/build", isDirectory: true),
    withIntermediateDirectories: true)

  func installExecutable(_ product: String) throws {
    let path = bin.appendingPathComponent(product)
    try Data("#!/bin/sh\necho \(product)\n".utf8).write(to: path)
    try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path.path)
  }

  func writeSidecar(_ product: String, payload: [String: String]) throws {
    let sidecarDirectory = bin.appendingPathComponent("\(product).metadata", isDirectory: true)
    try fm.createDirectory(at: sidecarDirectory, withIntermediateDirectories: true)
    let plist = try PropertyListSerialization.data(
      fromPropertyList: payload, format: .xml, options: 0)
    try plist.write(to: sidecarDirectory.appendingPathComponent("Info.plist"))
  }

  func writeAppcast(_ product: String, feedVersion: String, critical: Bool = false) throws -> URL {
    let feedURL = serve.appendingPathComponent("\(product).appcast.xml")
    let criticalAttribute = critical ? " sparkle:criticalUpdate=\"true\"" : ""
    try Data(
      """
      <?xml version="1.0" standalone="yes"?>
      <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
        <channel>
          <title>\(product)</title>
          <item>
            <title>\(feedVersion)</title>
            <enclosure url="\(serve.appendingPathComponent("\(product).bin").absoluteString)"
                       sparkle:version="\(feedVersion)"
                       sparkle:edSignature="AAAA"\(criticalAttribute)
                       length="1"
                       type="application/octet-stream"/>
          </item>
        </channel>
      </rss>
      """.utf8
    ).write(to: feedURL)
    return feedURL
  }

  func installSidecared(
    _ product: String, installedVersion: String, feedVersion: String, critical: Bool
  ) throws {
    try installExecutable(product)
    let feedURL = try writeAppcast(product, feedVersion: feedVersion, critical: critical)
    try writeSidecar(
      product,
      payload: [
        "CFBundleExecutable": product,
        "CFBundleShortVersionString": installedVersion,
        "CFBundleVersion": "42",
        "SUFeedURL": feedURL.absoluteString,
        "SUPublicEDKey": "AAAA",
      ])
  }

  for tool in tools {
    switch tool {
    case .sidecared(let product, let installedVersion, let feedVersion):
      try installSidecared(
        product, installedVersion: installedVersion, feedVersion: feedVersion, critical: false)
    case .criticallyBehind(let product, let installedVersion, let feedVersion):
      try installSidecared(
        product, installedVersion: installedVersion, feedVersion: feedVersion, critical: true)
    case .unreachableFeed(let product, let installedVersion):
      try installExecutable(product)
      let ghost = serve.appendingPathComponent("\(product).missing-appcast.xml")
      try writeSidecar(
        product,
        payload: [
          "CFBundleExecutable": product,
          "CFBundleShortVersionString": installedVersion,
          "SUFeedURL": ghost.absoluteString,
          "SUPublicEDKey": "AAAA",
        ])
    case .corruptSidecar(let product):
      try installExecutable(product)
      let sidecarDirectory = bin.appendingPathComponent("\(product).metadata", isDirectory: true)
      try fm.createDirectory(at: sidecarDirectory, withIntermediateDirectories: true)
      try Data("this is not a plist".utf8)
        .write(to: sidecarDirectory.appendingPathComponent("Info.plist"))
    case .bare(let product):
      try installExecutable(product)
    }
  }

  return bin
}

private func fleetReport(_ tools: [FixtureTool]) async throws -> FleetStatus.Report {
  let bin = try makeFleetFixture(tools)
  defer { try? FileManager.default.removeItem(at: bin.deletingLastPathComponent()) }
  return try await FleetStatus.report(binDirectory: bin)
}

// MARK: - CLI surface

@Test("CUJ-30 parses the fleet-status verb with --bin-dir and --format json")
func parsesFleetStatusVerb() throws {
  let command = try VaporizeCLI.parse([
    "fleet-status",
    "--bin-dir", "/tmp/fixture-bin",
    "--format", "json",
  ])
  #expect(command.mode == .fleetStatus)
  #expect(command.fleetBinDirectory == "/tmp/fixture-bin")
  #expect(command.vaporOutputFormat == .json)
}

// MARK: - (a) sidecared tool current vs a local file-URL feed

@Test("CUJ-30 a sidecared tool matching its feed's newest is `current`")
func sidecaredToolCurrent() async throws {
  let report = try await fleetReport([
    .sidecared(product: "alpha.cli@cuj30.clia.sh", installedVersion: "2.0.0", feedVersion: "2.0.0")
  ])
  let row = try #require(report.tools.first { $0.product == "alpha.cli@cuj30.clia.sh" })
  #expect(row.status == .current)
  #expect(row.installedVersion == "2.0.0")
  #expect(row.installedBuild == "42")
  #expect(row.latestVersion == "2.0.0")
  #expect(row.feedURL?.hasPrefix("file://") == true)
  #expect(report.summary.current == 1)
}

// MARK: - (b) sidecared tool behind

@Test("CUJ-30 a sidecared tool behind its feed is `behind` with the latest version recorded")
func sidecaredToolBehind() async throws {
  let report = try await fleetReport([
    .sidecared(product: "beta.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "2.5.0")
  ])
  let row = try #require(report.tools.first { $0.product == "beta.cli@cuj30.clia.sh" })
  #expect(row.status == .behind)
  #expect(row.installedVersion == "1.0.0")
  #expect(row.latestVersion == "2.5.0")
  #expect(row.detail?.contains("self-update --product beta.cli@cuj30.clia.sh") == true)
  #expect(report.summary.behind == 1)
}

// MARK: - critical lane: feed-declared minimum violated

@Test("CUJ-30 a tool behind a sparkle:criticalUpdate item is `critical-behind`, not merely behind")
func criticalUpdateIsCriticalBehind() async throws {
  let report = try await fleetReport([
    .criticallyBehind(
      product: "kappa.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "3.0.0"),
    .sidecared(product: "beta.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "2.0.0"),
  ])
  let row = try #require(report.tools.first { $0.product == "kappa.cli@cuj30.clia.sh" })
  #expect(row.status == .criticalBehind)
  #expect(row.installedVersion == "1.0.0")
  #expect(row.latestVersion == "3.0.0")
  #expect(row.detail?.contains("CRITICAL") == true)
  #expect(row.detail?.contains("feed-declared minimum 3.0.0") == true)
  #expect(report.summary.criticalBehind == 1)
  // The plainly-behind sibling stays merely `behind`.
  #expect(report.tools.first { $0.product == "beta.cli@cuj30.clia.sh" }?.status == .behind)
}

@Test("CUJ-30 a tool AT the critical version is current, never critical-behind")
func atCriticalVersionIsCurrent() async throws {
  let report = try await fleetReport([
    .criticallyBehind(
      product: "kappa.cli@cuj30.clia.sh", installedVersion: "3.0.0", feedVersion: "3.0.0")
  ])
  let row = try #require(report.tools.first { $0.product == "kappa.cli@cuj30.clia.sh" })
  #expect(row.status == .current)
}

// MARK: - (c) corrupt sidecar -> typed error surfaced in the row, not swallowed

@Test("CUJ-30 a corrupt sidecar surfaces the typed InstalledProductSidecarError in its row")
func corruptSidecarSurfacesTypedError() async throws {
  let report = try await fleetReport([
    .corruptSidecar(product: "gamma.cli@cuj30.clia.sh"),
    .sidecared(product: "alpha.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "1.0.0"),
  ])
  // The scan survived the corrupt row — the healthy sibling still reports.
  #expect(report.summary.total == 2)
  let row = try #require(report.tools.first { $0.product == "gamma.cli@cuj30.clia.sh" })
  #expect(row.status == .sidecarError)
  let detail = try #require(row.detail)
  // The typed error (malformedSidecar) names the product and the path.
  #expect(detail.contains("gamma.cli@cuj30.clia.sh"))
  #expect(detail.contains("not a valid property list"))
  #expect(report.summary.sidecarError == 1)
}

// MARK: - (d) no-sidecar tool listed, never hidden

@Test("CUJ-30 a tool without any sidecar is LISTED as `no-sidecar`, not skipped")
func noSidecarToolIsListed() async throws {
  let report = try await fleetReport([
    .bare(product: "delta.cli@cuj30.clia.sh"),
    .sidecared(product: "alpha.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "1.0.0"),
  ])
  #expect(report.summary.total == 2)
  let row = try #require(report.tools.first { $0.product == "delta.cli@cuj30.clia.sh" })
  #expect(row.status == .noSidecar)
  #expect(row.installedVersion == nil)
  #expect(row.detail?.contains("no update identity recorded") == true)
  #expect(report.summary.noSidecar == 1)
}

// MARK: - Additional degraded lanes (loud, typed, offline)

@Test("CUJ-30 an unreachable feed is `feed-unreachable`, keeping the installed version on the row")
func unreachableFeedIsTyped() async throws {
  let report = try await fleetReport([
    .unreachableFeed(product: "epsilon.cli@cuj30.clia.sh", installedVersion: "1.2.3")
  ])
  let row = try #require(report.tools.first { $0.product == "epsilon.cli@cuj30.clia.sh" })
  #expect(row.status == .feedUnreachable)
  #expect(row.installedVersion == "1.2.3")
  #expect(row.latestVersion == nil)
  #expect(row.detail != nil)
}

@Test("CUJ-30 a missing bin directory throws loudly; an empty fleet and an unscannable path never conflate")
func missingBinDirectoryThrows() async throws {
  let ghost = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("vaporize-cuj30-ghost-\(UUID().uuidString)", isDirectory: true)
  await #expect(throws: FleetStatusError.self) {
    _ = try await FleetStatus.report(binDirectory: ghost)
  }
}

// MARK: - Report shape: sorted rows, directories excluded, stable JSON

@Test("CUJ-30 rows are sorted by product; sidecar/domain directories are never products")
func reportShapeIsDeterministic() async throws {
  let report = try await fleetReport([
    .bare(product: "zeta.cli@cuj30.clia.sh"),
    .sidecared(product: "alpha.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "1.0.0"),
  ])
  #expect(report.tools.map(\.product) == ["alpha.cli@cuj30.clia.sh", "zeta.cli@cuj30.clia.sh"])
  // Directories (`<product>.metadata/`, `domain/`) must never surface as rows.
  #expect(!report.tools.contains { $0.product.hasSuffix(".metadata") || $0.product == "domain" })
}

@Test("CUJ-30 the JSON report keeps the documented stable field names")
func jsonFieldNamesAreStable() async throws {
  let report = try await fleetReport([
    .sidecared(product: "alpha.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "2.0.0")
  ])
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  let json = try #require(String(data: encoder.encode(report), encoding: .utf8))
  for field in [
    "\"binDirectory\"", "\"tools\"", "\"summary\"",
    "\"product\"", "\"installedVersion\"", "\"installedBuild\"", "\"feedURL\"", "\"latestVersion\"",
    "\"status\"", "\"detail\"",
    "\"total\"", "\"current\"", "\"behind\"", "\"criticalBehind\"", "\"unknown\"",
    "\"feedUnreachable\"", "\"feedMalformed\"",
    "\"noSidecar\"", "\"noUpdateIdentity\"", "\"sidecarError\"",
  ] {
    #expect(json.contains(field), "missing stable field \(field)")
  }
  #expect(json.contains("\"behind\" : 1"))
}

@Test("CUJ-30 the text table is aligned and carries findings on continuation lines")
func textTableRenders() async throws {
  let report = try await fleetReport([
    .sidecared(product: "alpha.cli@cuj30.clia.sh", installedVersion: "1.0.0", feedVersion: "2.0.0"),
    .bare(product: "delta.cli@cuj30.clia.sh"),
  ])
  let table = FleetStatus.renderTable(report)
  let lines = table.split(separator: "\n").map(String.init)
  #expect(lines[0].hasPrefix("fleet-status: "))
  #expect(lines[0].contains("tools=2 current=0 behind=1"))
  let header = try #require(lines.first { $0.hasPrefix("PRODUCT") })
  #expect(header.contains("BUILD"))
  let alphaRow = try #require(lines.first { $0.hasPrefix("alpha.cli@cuj30.clia.sh") })
  // Column alignment: STATUS starts at the same offset in header and rows.
  let headerStatusOffset = try #require(header.range(of: "STATUS")?.lowerBound)
  let rowStatusOffset = try #require(alphaRow.range(of: "behind")?.lowerBound)
  #expect(
    header.distance(from: header.startIndex, to: headerStatusOffset)
      == alphaRow.distance(from: alphaRow.startIndex, to: rowStatusOffset))
  // The no-sidecar finding rides an indented continuation line.
  #expect(lines.contains { $0.hasPrefix("    ! No metadata sidecar") })
}
