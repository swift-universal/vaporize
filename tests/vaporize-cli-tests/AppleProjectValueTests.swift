import AppleProjectSpecCore
import Foundation
import Testing

@Test("AppleProjectValue decodes scalar and container values")
func appleProjectValueDecodesScalarAndContainerValues() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: value-fixture
    settings:
      base:
        BOOL_VALUE: true
        INT_VALUE: 7
        DOUBLE_VALUE: 6.4
        STRING_VALUE: "6.4"
        ARRAY_VALUE:
          - one
          - 2
        OBJECT_VALUE:
          nested: yes
    targets:
      app:
        type: application
        platform: macOS
    """
  )

  let base = try #require(spec.settings?.base)
  #expect(base["BOOL_VALUE"]?.boolValue == true)
  #expect(base["INT_VALUE"]?.stringValue == "7")
  #expect(base["DOUBLE_VALUE"]?.stringValue == "6.4")
  #expect(base["STRING_VALUE"]?.stringValue == "6.4")
  #expect(base["ARRAY_VALUE"]?.stringValue == nil)
  #expect(base["OBJECT_VALUE"]?.stringValue == nil)
}

@Test("Source entries decode from string shorthand")
func sourceEntriesDecodeFromStringShorthand() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: source-fixture
    targets:
      app:
        type: application
        platform: macOS
        sources:
          - Sources/App
    """
  )

  #expect(spec.targets["app"]?.sources?.map(\.path) == ["Sources/App"])
}

@Test("Renderer output decodes back into AppleProjectSpec")
func rendererOutputDecodesBackIntoAppleProjectSpec() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: render-fixture
    settings:
      base:
        SWIFT_VERSION: "6.4"
    targets:
      app:
        type: application
        platform: macOS
        settings:
          base:
            GENERATE_INFOPLIST_FILE: false
    """
  )
  let rendered = try AppleProjectYMLRenderer.renderData(spec: spec)
  let decoded = try AppleProjectYMLReader.decode(data: rendered)

  #expect(decoded == spec)
  #expect(String(decoding: rendered, as: UTF8.self).contains("SWIFT_VERSION: '6.4'"))
}
