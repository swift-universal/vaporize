import AppleProjectSpecCore
import Foundation
import Testing

@Test("Bundle resolver expands Concourse debug and release wrapper names")
func bundleResolverExpandsConcourseWrapperNames() throws {
  let spec = try AppleProjectYMLReader.load(url: concourseProjectYMLURL)

  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "concourse",
      configuration: "Debug"
    ) == "concourse-0.1.0-debug"
  )
  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "concourse",
      configuration: "Release"
    ) == "concourse-0.1.0-testflight"
  )
}

@Test("Bundle resolver uses case-insensitive configuration names")
func bundleResolverUsesCaseInsensitiveConfigurationNames() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: fixture
    targets:
      app:
        type: application
        platform: macOS
        settings:
          base:
            PRODUCT_NAME: fixture
            MARKETING_VERSION: 3.1.0
          configs:
            debug:
              WRAPPER_NAME: "$(PRODUCT_NAME)-$(MARKETING_VERSION)-dev.app"
    """
  )

  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "app",
      configuration: "Debug"
    ) == "fixture-3.1.0-dev"
  )
}

@Test("Bundle resolver falls back to the single target")
func bundleResolverFallsBackToSingleTarget() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: fixture
    targets:
      actual-app:
        type: application
        platform: macOS
        settings:
          base:
            PRODUCT_NAME: actual-app
            WRAPPER_NAME: "$(PRODUCT_NAME).app"
    """
  )

  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "missing-target",
      configuration: "Debug"
    ) == "actual-app"
  )
}

@Test("Bundle resolver rejects unresolved wrapper placeholders")
func bundleResolverRejectsUnresolvedWrapperPlaceholders() throws {
  let spec = try decodeAppleProjectYML(
    """
    name: fixture
    targets:
      app:
        type: application
        platform: macOS
        settings:
          base:
            WRAPPER_NAME: "$(PRODUCT_NAME)-$(MISSING_VERSION).app"
    """
  )

  #expect(
    AppleProjectAppBundleNameResolver.appBundleName(
      in: spec,
      targetName: "app",
      configuration: "Debug"
    ) == nil
  )
}
