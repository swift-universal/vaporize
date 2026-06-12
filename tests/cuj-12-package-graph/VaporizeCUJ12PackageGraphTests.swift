import ArgumentParser
import Testing

@testable import VaporizeCLI

@Test("CUJ-12 parses graph forwarded arguments without interpreting them")
func parsesGraphForwardedArgumentsWithoutInterpretingThem() throws {
  let command = try VaporizeCLI.parse([
    "graph",
    "--package-path",
    "/workspace/package-graph",
    "--",
    "impact",
    "--format",
    "json",
  ])

  #expect(command.mode == .graph)
  #expect(command.packagePath == "/workspace/package-graph")
  #expect(command.forwardedArguments == ["impact", "--format", "json"])
}
