public import Foundation

/// A version of the SARIF specification.
public enum SARIFVersion: String, Comparable, Codable, Sendable {
  case v2_1_0 = "2.1.0"

  /// The JSON schema URL for this version of the SARIF specification.
  public var schema: URL {
    switch self {
    case .v2_1_0:
      URL(
        string:
          "https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/schemas/sarif-schema-2.1.0.json"
      )!
    }
  }

  /// The minimum supported SARIF version.
  public static let min = SARIFVersion.v2_1_0
  /// The maximum supported SARIF version.
  public static let max = SARIFVersion.v2_1_0

  /// Determine if one SARIF version is less than another SARIF version.
  public static func < (lhs: SARIFVersion, rhs: SARIFVersion) -> Bool {
    false  // Only one value so far.
  }
}
