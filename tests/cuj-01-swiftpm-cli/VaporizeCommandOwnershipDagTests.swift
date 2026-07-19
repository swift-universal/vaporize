import Foundation
import Testing

@testable import VaporizeCLI

private struct VaporizeCommandDag: Decodable {
  struct Node: Decodable {
    let id: String
    let rank: Int
    let lane: Int
  }

  struct Edge: Decodable {
    let from: String
    let to: String
  }

  let schemaVersion: String
  let model: String
  let nodes: [Node]
  let edges: [Edge]
}

private func vaporizePackageDirectory() -> URL {
  URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
}

private func vaporizeCommandDag() throws -> VaporizeCommandDag {
  let url = vaporizePackageDirectory()
    .appendingPathComponent("architecture", isDirectory: true)
    .appendingPathComponent("vaporize.public-surface.dag.json")
  return try JSONDecoder().decode(
    VaporizeCommandDag.self,
    from: Data(contentsOf: url)
  )
}

private func generatedManualLongOptions() throws -> Set<String> {
  let url = vaporizePackageDirectory()
    .appendingPathComponent("Documentation/man/man1", isDirectory: true)
    .appendingPathComponent("vaporize.cli@wrkstrm-core.clia.sh.1")
  let manual = try String(contentsOf: url, encoding: .utf8)
  let synopsisPrefix = ".Op Fl -"
  return Set(
    manual.split(separator: "\n").compactMap { line in
      guard line.hasPrefix(synopsisPrefix) else { return nil }
      let remainder = line.dropFirst(synopsisPrefix.count)
      let name = remainder.prefix { !$0.isWhitespace }
      return name.isEmpty ? nil : "--\(name)"
    }
  )
}

private func ownershipMapLongOptions() throws -> Set<String> {
  let url = vaporizePackageDirectory()
    .appendingPathComponent("vaporize.engineering.docc", isDirectory: true)
    .appendingPathComponent("command-ownership-map.md")
  let map = try String(contentsOf: url, encoding: .utf8)
  let expression = try NSRegularExpression(pattern: #"--[a-z0-9][a-z0-9-]*"#)
  let range = NSRange(map.startIndex..<map.endIndex, in: map)
  return Set(
    expression.matches(in: map, range: range).compactMap { match in
      Range(match.range, in: map).map { String(map[$0]) }
    }
  )
}

@Test("Vaporize public modes exactly match the canonical command DAG")
func publicModesMatchCanonicalCommandDag() throws {
  let dag = try vaporizeCommandDag()
  let graphModes = Set(
    dag.nodes.compactMap { node in
      node.id.hasPrefix("mode.") ? String(node.id.dropFirst("mode.".count)) : nil
    }
  )
  let implementedModes = Set(VaporizeCLI.Mode.allCases.map(\.rawValue))

  #expect(dag.schemaVersion == "0.0.1")
  #expect(dag.model == "DagModel")
  #expect(graphModes == implementedModes)
}

@Test("Vaporize command ownership graph is structurally a DAG")
func commandOwnershipGraphIsStructurallyADag() throws {
  let dag = try vaporizeCommandDag()
  let ids = dag.nodes.map(\.id)
  let idSet = Set(ids)

  #expect(idSet.count == ids.count)
  #expect(dag.nodes.allSatisfy { $0.rank >= 0 && $0.lane >= 0 })
  #expect(dag.edges.allSatisfy { idSet.contains($0.from) && idSet.contains($0.to) })

  var indegree = Dictionary(uniqueKeysWithValues: ids.map { ($0, 0) })
  var successors = Dictionary(uniqueKeysWithValues: ids.map { ($0, [String]()) })
  for edge in dag.edges {
    indegree[edge.to, default: 0] += 1
    successors[edge.from, default: []].append(edge.to)
  }

  var frontier = indegree.filter { $0.value == 0 }.map(\.key)
  var visited = 0
  while let node = frontier.popLast() {
    visited += 1
    for successor in successors[node, default: []] {
      indegree[successor, default: 0] -= 1
      if indegree[successor] == 0 {
        frontier.append(successor)
      }
    }
  }

  #expect(visited == ids.count)
}

@Test("Vaporize ownership map covers every generated man-page long option")
func ownershipMapCoversGeneratedManualOptions() throws {
  let manualOptions = try generatedManualLongOptions()
  let mappedOptions = try ownershipMapLongOptions()
  let missingOptions = manualOptions.subtracting(mappedOptions)

  #expect(!manualOptions.isEmpty)
  #expect(missingOptions.isEmpty)
}

#if os(macOS)
  @Test("Vaporize command DAG exposes Xcode selection as a macOS-only branch")
  func commandDagExposesMacOSXcodeSelection() throws {
    let ids = Set(try vaporizeCommandDag().nodes.map(\.id))
    #expect(ids.contains("provider.xcode"))
    #expect(ids.contains("operation.xcode-select"))
    #expect(ids.contains("option.xcode-switch"))
    #expect(ids.contains("option.xcode-reset"))
    #expect(ids.contains("option.xcode-print-path"))
  }
#endif
