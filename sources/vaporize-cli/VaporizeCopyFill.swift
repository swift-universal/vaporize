import Foundation

/// Applies the typed copy package's positional `{aN}` placeholders without
/// allowing runtime values to become source literals.
func vaporizeCopyFill(_ template: String, _ arguments: [String]) -> String {
  arguments.enumerated().reduce(template) { rendered, item in
    rendered.replacingOccurrences(of: "{a\(item.offset + 1)}", with: item.element)
  }
}
