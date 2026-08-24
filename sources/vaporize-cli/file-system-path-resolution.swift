import Foundation

enum VaporizeFileSystemPathResolution {
  static func isAbsolute(_ path: String) -> Bool {
    guard !path.isEmpty else { return false }

    if path.hasPrefix("/") || path.hasPrefix("\\") {
      return true
    }

    let characters = Array(path.utf8)
    guard characters.count >= 3 else { return false }

    let drive = characters[0]
    let isDriveLetter = (65...90).contains(drive) || (97...122).contains(drive)
    let hasDriveSeparator = characters[1] == 58
    let hasRootSeparator = characters[2] == 47 || characters[2] == 92
    return isDriveLetter && hasDriveSeparator && hasRootSeparator
  }

  static func absoluteURL(
    for path: String,
    relativeTo currentDirectoryURL: URL
  ) -> URL {
    if isAbsolute(path) {
      return URL(fileURLWithPath: path).standardizedFileURL
    }

    return currentDirectoryURL
      .appendingPathComponent(path)
      .standardizedFileURL
  }
}
