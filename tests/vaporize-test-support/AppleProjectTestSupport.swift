import AppleProjectSpecCore
import Foundation

public let vaporizeTestPackageRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

public let concourseProjectYMLURL = vaporizeTestPackageRoot
  .appendingPathComponent("../../apps/concourse/project.yml")
  .standardizedFileURL

public let concourseProjectPklURL = vaporizeTestPackageRoot
  .appendingPathComponent("../../apps/concourse/project.pkl")
  .standardizedFileURL

public let expectedConcourseTargetNames = ["concourse", "concourse-tests-ui"]
public let expectedConcourseBuildableTargetNames = ["concourse"]
public let expectedConcoursePackageNames = [
  "WrkstrmOnboarding",
  "WrkstrmWalkthrough",
  "common-feature-flags",
  "common-terminal",
  "swift-snapshot-testing",
]

public let appleProjectSpecPklSchemaURL = vaporizeTestPackageRoot
  .appendingPathComponent("Pkl/AppleProjectSpec.pkl")
  .standardizedFileURL

public func decodeAppleProjectYML(_ yaml: String) throws -> AppleProjectSpec {
  try AppleProjectYMLReader.decode(data: Data(yaml.utf8))
}

public func relativePathForPklAmends(from baseDirectory: URL, to target: URL) -> String {
  let baseComponents = baseDirectory.standardizedFileURL.pathComponents
  let targetComponents = target.standardizedFileURL.pathComponents

  var commonPrefixCount = 0
  while commonPrefixCount < baseComponents.count,
    commonPrefixCount < targetComponents.count,
    baseComponents[commonPrefixCount] == targetComponents[commonPrefixCount]
  {
    commonPrefixCount += 1
  }

  guard commonPrefixCount > 0 else {
    return target.standardizedFileURL.path
  }

  let up = Array(repeating: "..", count: baseComponents.count - commonPrefixCount)
  let down = Array(targetComponents.dropFirst(commonPrefixCount))
  let components = up + down
  return components.isEmpty ? "." : components.joined(separator: "/")
}
