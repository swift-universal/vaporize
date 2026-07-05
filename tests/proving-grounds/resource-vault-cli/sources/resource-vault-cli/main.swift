import Darwin
import Foundation

struct Catalog: Decodable {
  struct Entry: Decodable {
    var slug: String
    var weight: Int
  }

  var name: String
  var entries: [Entry]
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments == ["catalog"] else {
  fputs("usage: resource-vault catalog\n", stderr)
  exit(64)
}

guard let catalogURL = Bundle.module.url(
  forResource: "catalog",
  withExtension: "json",
  subdirectory: "resources"
) else {
  fputs("missing catalog resource\n", stderr)
  exit(42)
}

guard let messageURL = Bundle.module.url(
  forResource: "message",
  withExtension: "txt",
  subdirectory: "resources/payloads"
) else {
  fputs("missing payload resource\n", stderr)
  exit(43)
}

do {
  let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: catalogURL))
  let message = try String(contentsOf: messageURL, encoding: .utf8)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  let slugs = catalog.entries.map(\.slug).joined(separator: ",")
  let weight = catalog.entries.reduce(0) { $0 + $1.weight }
  print("vault:\(catalog.name):\(catalog.entries.count):\(weight):\(message):\(slugs)")
} catch {
  fputs("resource vault read failed: \(error)\n", stderr)
  exit(44)
}
