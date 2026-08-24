import Foundation

/// Pure decision for `vaporize upgrade-project-yml-to-pkl`.
///
/// Given the parity result between the freshly-imported `project.pkl` and the
/// source `project.yml`, and whether `--apply` was passed, decide whether the
/// legacy `project.yml` may be retired. The rule is deliberately strict:
///
/// - Parity mismatch **always** blocks retirement — the generated pkl must
///   reproduce the yml before the yml can be removed, so an upgrade can never
///   silently drop project configuration.
/// - Without `--apply`, the upgrade is a preview: both files are kept.
/// - With `--apply` and a clean parity, the `project.yml` is retired.
///
/// Kept filesystem-free so the whole option space is unit-testable; the CLI
/// runs the import + comparison and hands the result here.
public enum XcodeProjectPklUpgradePlanner {

  public enum Decision: Equatable, Sendable {
    /// Parity mismatch: the generated pkl does not reproduce the yml. The yml is
    /// kept; the caller must surface `mismatches` loudly and exit non-zero.
    case blockedByParity(mismatches: [String])
    /// Parity matched but `--apply` was not given: keep both files, report the
    /// preview and how to apply.
    case previewed
    /// Parity matched and `--apply` given: retire the `project.yml`.
    case upgraded(retireYml: Bool)
  }

  public static func decide(parityMatched: Bool, mismatches: [String], apply: Bool) -> Decision {
    if !parityMatched {
      return .blockedByParity(mismatches: mismatches)
    }
    if !apply {
      return .previewed
    }
    return .upgraded(retireYml: true)
  }
}
