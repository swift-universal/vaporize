import FixtureIssueSupport
import Testing

@Suite
struct SwiftTestingExpectedTests {
  @Test
  func reportsExpectedIssue() {
    FixtureIssueSupport.reportExpected()
  }
}
