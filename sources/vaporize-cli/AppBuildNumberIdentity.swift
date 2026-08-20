import Foundation

/// Source mutation + expected bundle identity for one explicit Vaporize app
/// build/install collapse. This is not a release approval or a runtime claim.
struct AppBuildNumberIdentity: Sendable {
  let marketingVersion: String
  let buildNumber: Int
  let sourceCarrierPath: String
  let receipt: VaporizeBuildNumberReceipt

  var xcodeBuildSetting: String { "CURRENT_PROJECT_VERSION=\(buildNumber)" }
}

/// Typed record connecting the changed source carrier to the identity Vaporize
/// expects in both the built and installed app bundles.
struct VaporizeBuildNumberReceipt: Codable, Sendable {
  let kind: String
  let schemaVersion: String
  let capturedAt: String
  let operation: String
  let product: String
  let configuration: String
  let bundleMarketingVersion: String
  let previousBuildNumber: Int
  let nextBuildNumber: Int
  let sourceCarrierPath: String
  let sourceCarrierKind: String
  let xcodeBuildSetting: String
  let dirtyWorktreePolicy: String
  let evidenceBoundary: String
}
