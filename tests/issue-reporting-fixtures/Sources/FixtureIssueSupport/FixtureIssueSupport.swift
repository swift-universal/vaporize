import IssueReporting
import VaporizeIssueReporting

public enum FixtureIssueSupport {
  public static func reportUnexpected() {
    guard let configuration = VaporizeIssueReporting.configurationFromEnvironment(
      product: "fixture.cli@vaporize-tests.clia.sh"
    ) else {
      reportIssue("fixture unexpected issue")
      return
    }
    VaporizeIssueReporting.withReporter(configuration: configuration) {
      reportIssue("fixture unexpected issue")
    }
  }

  public static func reportExpected() {
    _withKnownIssue("fixture expected issue") {
      guard let configuration = VaporizeIssueReporting.configurationFromEnvironment(
        product: "fixture.cli@vaporize-tests.clia.sh"
      ) else {
        reportIssue("fixture expected issue")
        return
      }
      VaporizeIssueReporting.withExpectedReporter(configuration: configuration) {
        reportIssue("fixture expected issue")
      }
    }
  }
}
