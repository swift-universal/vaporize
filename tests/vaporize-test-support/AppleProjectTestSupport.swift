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

public func decodeAppleProjectYML(_ yaml: String) throws -> AppleProjectSpec {
  try AppleProjectYMLReader.decode(data: Data(yaml.utf8))
}
