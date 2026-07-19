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

private func vaporizeCommandDag() throws -> VaporizeCommandDag {
  let packageDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
  let url = packageDirectory
    .appendingPathComponent("vaporize.engineering.docc", isDirectory: true)
    .appendingPathComponent("vaporize-command-ownership.dag.json")
  return try JSONDecoder().decode(
    VaporizeCommandDag.self,
    from: Data(contentsOf: url)
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
