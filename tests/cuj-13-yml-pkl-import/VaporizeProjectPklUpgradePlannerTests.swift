import AppleProjectSpecCore
import Foundation
import Testing

/// Proving ground for the parity-gated upgrade decision
/// (`AppleProjectPklUpgradePlanner`), the retire-or-keep core of
/// `vaporize upgrade-project-yml-to-pkl` (FR-VAPORIZE-UPGRADE-PROJECT-YML-TO-PKL).
/// Sweeps the full (parityMatched × apply) option space and pins the invariant
/// that matters: the project.yml is retired on exactly ONE combination
/// (parity-matched AND apply), and a parity mismatch NEVER retires it.

/// The decision option space: parity result × apply flag.
private let upgradeCases: [(parityMatched: Bool, apply: Bool)] = [
  (true, true), (true, false), (false, true), (false, false),
]

@Test("upgrade decision across the full (parity × apply) option space", arguments: upgradeCases)
func decisionAcrossOptionSpace(parityMatched: Bool, apply: Bool) {
  let decision = AppleProjectPklUpgradePlanner.decide(
    parityMatched: parityMatched,
    mismatches: parityMatched ? [] : ["targets"],
    apply: apply)

  switch (parityMatched, apply) {
  case (false, _):
    #expect(decision == .blockedByParity(mismatches: ["targets"]))
  case (true, false):
    #expect(decision == .previewed)
  case (true, true):
    #expect(decision == .upgraded(retireYml: true))
  }
}

/// The load-bearing safety invariant: the yml is retired on exactly one of the
/// four combinations.
@Test("project.yml is retired on exactly one combination (parity-matched + apply)")
func retiresOnExactlyOneCombination() {
  var retireCount = 0
  for parityMatched in [true, false] {
    for apply in [true, false] {
      if case .upgraded(retireYml: true) = AppleProjectPklUpgradePlanner.decide(
        parityMatched: parityMatched, mismatches: [], apply: apply) {
        retireCount += 1
      }
    }
  }
  #expect(retireCount == 1)
}

/// A parity mismatch blocks retirement even with --apply, and carries the
/// mismatched field names for the loud CLI error.
@Test("parity mismatch blocks retirement even with --apply, and carries mismatches")
func parityMismatchBlocksEvenWithApply() {
  let decision = AppleProjectPklUpgradePlanner.decide(
    parityMatched: false, mismatches: ["packages", "schemes"], apply: true)
  #expect(decision == .blockedByParity(mismatches: ["packages", "schemes"]))
  if case .upgraded = decision {
    Issue.record("a parity mismatch must never produce an .upgraded decision")
  }
}

/// A clean parity without --apply is a non-destructive preview.
@Test("clean parity without --apply is a preview (no retirement)")
func cleanParityWithoutApplyIsPreview() {
  #expect(
    AppleProjectPklUpgradePlanner.decide(parityMatched: true, mismatches: [], apply: false)
      == .previewed)
}
