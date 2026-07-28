import CommonLog
import Darwin
import Foundation
import IssueReporting

struct Catalog: Decodable {
  struct Entry: Decodable {
    var slug: String
    var weight: Int
  }

  var name: String
  var entries: [Entry]
}

// Both loggers stay at Common Log's default `.critical` exposure — the
// process-wide release floor is never lowered. Production-essential protocol
// output and user-facing diagnostics instead go through `Log.critical(_:)`,
// the nonfatal-critical emission method built for exactly this (Log.swift:
// "Use this for production-essential protocol output or diagnostics that
// must remain visible under Common Log's critical-only release default.").
var diagnosticLog = Log(
  system: "resource-vault",
  category: "cli",
  options: [.prod],
  backend: StandardErrorLogBackend()
)
diagnosticLog.decorator = Log.Decorator.Plain()

var payloadLog = Log(
  system: "resource-vault",
  category: "cli",
  options: [.prod],
  backend: StandardOutputLogBackend()
)
payloadLog.decorator = Log.Decorator.Plain()

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments == ["catalog"] else {
  diagnosticLog.critical("usage: resource-vault catalog")
  exit(64)
}

guard let catalogURL = Bundle.module.url(
  forResource: "catalog",
  withExtension: "json",
  subdirectory: "resources"
) else {
  reportIssue("resource-vault: missing catalog resource; the tool was built without its bundled catalog.json")
  diagnosticLog.critical("missing catalog resource")
  exit(42)
}

guard let messageURL = Bundle.module.url(
  forResource: "message",
  withExtension: "txt",
  subdirectory: "resources/payloads"
) else {
  reportIssue("resource-vault: missing payload resource; the tool was built without its bundled payloads/message.txt")
  diagnosticLog.critical("missing payload resource")
  exit(43)
}

do {
  let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: catalogURL))
  let message = try String(contentsOf: messageURL, encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  let slugs = catalog.entries.map(\.slug).joined(separator: ",")
  let weight = catalog.entries.reduce(0) { $0 + $1.weight }
  payloadLog.critical("vault:\(catalog.name):\(catalog.entries.count):\(weight):\(message):\(slugs)")
} catch {
  reportIssue(error, "resource-vault: bundled resource is present but unreadable/undecodable")
  diagnosticLog.critical("resource vault read failed: \(error)")
  exit(44)
}
