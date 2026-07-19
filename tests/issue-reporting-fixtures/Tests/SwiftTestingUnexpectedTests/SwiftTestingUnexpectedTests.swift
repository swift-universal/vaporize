import FixtureIssueSupport
import Testing

@Suite
struct SwiftTestingUnexpectedTests {
  @Test
  func reportsUnexpectedIssue() {
    FixtureIssueSupport.reportUnexpected()
  }
}
