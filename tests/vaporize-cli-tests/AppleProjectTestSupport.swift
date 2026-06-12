import AppleProjectSpecCore
import Foundation

let vaporizeTestPackageRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

let concourseProjectYMLURL = vaporizeTestPackageRoot
  .appendingPathComponent("../../apps/concourse/project.yml")
  .standardizedFileURL

let concourseProjectPklURL = vaporizeTestPackageRoot
  .appendingPathComponent("../../apps/concourse/project.pkl")
  .standardizedFileURL

func decodeAppleProjectYML(_ yaml: String) throws -> AppleProjectSpec {
  try AppleProjectYMLReader.decode(data: Data(yaml.utf8))
}
