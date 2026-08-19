import Foundation

/// A BuildMMSS projection for one already-reserved Calendar-Origin source
/// coordinate. Its numeric sequence comes from the shared Bump Build carrier
/// plan; this source-level stamp neither reserves a coordinate nor builds,
/// installs, publishes, or approves an artifact.
struct TemporalBuildStamp: Codable, Equatable, Sendable {
  let stampModel: String
  let sourceCoordinate: String
  let resolvingVersion: String
  let buildSequence: Int
  let previousBuildSequence: Int
  let buildCarrierKind: String
  let buildCarrierPath: String
  let buildCarrierMode: String
  let mintMMSS: String
  let buildMMSS: String
  let fullReleaseVersion: String
  let stampedAt: String
  let claims: [String]
  let nonClaims: [String]

  enum CodingKeys: String, CodingKey {
    case stampModel = "vaporize-temporal-build-stamp"
    case sourceCoordinate
    case resolvingVersion
    case buildSequence
    case previousBuildSequence
    case buildCarrierKind
    case buildCarrierPath
    case buildCarrierMode
    case mintMMSS
    case buildMMSS
    case fullReleaseVersion
    case stampedAt
    case claims
    case nonClaims
  }

  static func stamp(
    sourceCoordinate: String,
    buildSequence: Int,
    previousBuildSequence: Int,
    buildCarrierKind: String,
    buildCarrierPath: String,
    buildCarrierMode: String,
    stampedAt: Date
  ) throws -> Self {
    let coordinate = try TemporalSourceCoordinate(sourceCoordinate)
    guard (1...999).contains(buildSequence) else {
      throw TemporalBuildStampError.invalidBuildSequence(buildSequence)
    }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let minute = calendar.component(.minute, from: stampedAt)
    let second = calendar.component(.second, from: stampedAt)
    let mintMMSS = String(format: "%02d%02d", minute, second)
    let buildMMSS = String(format: "%03d%@", buildSequence, mintMMSS)
    let resolvingVersion = coordinate.resolvingVersion

    return Self(
      stampModel: "0.0.1",
      sourceCoordinate: coordinate.rawValue,
      resolvingVersion: resolvingVersion,
      buildSequence: buildSequence,
      previousBuildSequence: previousBuildSequence,
      buildCarrierKind: buildCarrierKind,
      buildCarrierPath: buildCarrierPath,
      buildCarrierMode: buildCarrierMode,
      mintMMSS: mintMMSS,
      buildMMSS: buildMMSS,
      fullReleaseVersion: "\(resolvingVersion)+\(buildMMSS)",
      stampedAt: Self.utcString(from: stampedAt),
      claims: [
        "utc-derived-BuildMMSS",
        "BuildMMSS-is-outside-source-coordinate",
        "build-sequence-planned-by-bump-build",
        "ready-for-Vaporize-product-version-and-product-build"
      ],
      nonClaims: [
        "no-source-coordinate-reservation",
        "no-bump-build-apply-performed",
        "no-build-or-install-performed",
        "no-publication-performed",
        "no-human-approval-performed"
      ]
    )
  }

  static func parseUTC(_ value: String?) throws -> Date {
    guard let value else { return .now }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: value) { return date }
    formatter.formatOptions = [.withInternetDateTime]
    guard let date = formatter.date(from: value) else {
      throw TemporalBuildStampError.invalidUTCInstant(value)
    }
    return date
  }

  static func utcString(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }
}

private struct TemporalSourceCoordinate {
  let rawValue: String
  let major: Int
  let yearMonth: String
  let dayHourRevision: String

  init(_ rawValue: String) throws {
    let segments = rawValue.split(separator: "_", omittingEmptySubsequences: false)
    guard segments.count == 3,
      segments[0].first == "v",
      segments[0].count == 5,
      segments[1].count == 4,
      segments[2].count == 5,
      Self.isASCIIDecimal(segments[0].dropFirst()),
      Self.isASCIIDecimal(segments[1]),
      Self.isASCIIDecimal(segments[2])
    else {
      throw TemporalBuildStampError.invalidSourceCoordinate(rawValue)
    }

    let majorText = String(segments[0].dropFirst())
    let monthText = segments[1].suffix(2)
    guard let major = Int(majorText),
      let month = Int(monthText),
      let dayHourRevision = Int(segments[2])
    else {
      throw TemporalBuildStampError.invalidSourceCoordinate(rawValue)
    }
    let day = dayHourRevision / 1_000
    let hour = (dayHourRevision % 1_000) / 10
    guard (1...12).contains(month),
      (1...31).contains(day),
      (0...23).contains(hour)
    else {
      throw TemporalBuildStampError.invalidSourceCoordinate(rawValue)
    }

    self.rawValue = rawValue
    self.major = major
    self.yearMonth = String(segments[1])
    self.dayHourRevision = String(segments[2])
  }

  private static func isASCIIDecimal<S: StringProtocol>(_ value: S) -> Bool {
    !value.isEmpty && value.unicodeScalars.allSatisfy { (48...57).contains($0.value) }
  }

  var resolvingVersion: String {
    "\(major).\(yearMonth).\(dayHourRevision)"
  }
}

enum TemporalBuildStampError: Error, Equatable, LocalizedError {
  case invalidSourceCoordinate(String)
  case invalidBuildSequence(Int)
  case invalidUTCInstant(String)

  var errorDescription: String? {
    switch self {
    case let .invalidSourceCoordinate(value):
      "source coordinate must use vNNNN_YYMM_DDHHr with a valid UTC month, day, and hour: \(value)"
    case let .invalidBuildSequence(value):
      "build sequence must be between 1 and 999: \(value)"
    case let .invalidUTCInstant(value):
      "timestamp must be an ISO-8601 UTC instant: \(value)"
    }
  }
}
