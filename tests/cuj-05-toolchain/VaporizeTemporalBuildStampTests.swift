import Foundation
import Testing

@testable import VaporizeCLI

@Test("Temporal stamp derives BuildMMSS from an explicit UTC instant")
func temporalStampDerivesBuildMMSS() throws {
  let timestamp = try TemporalBuildStamp.parseUTC("2026-08-19T07:38:26Z")
  let stamp = try TemporalBuildStamp.stamp(
    sourceCoordinate: "v0001_2608_19070",
    buildSequence: 2,
    stampedAt: timestamp
  )

  #expect(stamp.resolvingVersion == "1.2608.19070")
  #expect(stamp.mintMMSS == "3826")
  #expect(stamp.buildMMSS == "0023826")
  #expect(stamp.fullReleaseVersion == "1.2608.19070+0023826")
  #expect(stamp.sourceCoordinate == "v0001_2608_19070")
}

@Test("Temporal stamp refuses an invalid Calendar-Origin coordinate")
func temporalStampRefusesInvalidCoordinate() {
  #expect(throws: TemporalBuildStampError.self) {
    try TemporalBuildStamp.stamp(
      sourceCoordinate: "v0001_2608_19970",
      buildSequence: 2,
      stampedAt: .now
    )
  }
}

@Test("Temporal stamp refuses an invalid Calendar-Origin month")
func temporalStampRefusesInvalidMonth() {
  #expect(throws: TemporalBuildStampError.self) {
    try TemporalBuildStamp.stamp(
      sourceCoordinate: "v0001_2613_19070",
      buildSequence: 2,
      stampedAt: .now
    )
  }
}

@Test("Temporal stamp refuses a sequence outside the three-digit BuildMMSS range")
func temporalStampRefusesInvalidSequence() {
  #expect(throws: TemporalBuildStampError.self) {
    try TemporalBuildStamp.stamp(
      sourceCoordinate: "v0001_2608_19070",
      buildSequence: 1_000,
      stampedAt: .now
    )
  }
}
