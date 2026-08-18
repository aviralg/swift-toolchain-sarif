/// A SARIF [versioned hierarchical string](https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790691),
/// a hierarchical string in which the final component may optionally specify a non-negative version number, prefixed with a "v".
public struct VersionedHierarchicalString: Codable, Hashable, Sendable,
  CustomStringConvertible,
  ExpressibleByStringLiteral
{
  public let version: UInt32?
  public let withoutVersion: HierarchicalString
  public let withVersion: HierarchicalString

  public var string: String {
    self.withVersion.string
  }

  public init(stringLiteral string: String) {
    try! self.init(parsing: string)
  }

  public init(parsing string: String) throws(SARIFError) {
    self.withVersion = .init(parsing: string)
    if let lastComponent = self.withVersion.components.last {
      let regex = /^v(0|(?:[1-9][0-9]*))$/
      if let match = lastComponent.wholeMatch(of: regex) {
        guard let version = UInt32(match.output.1) else {
          throw .invalidSARIF(
            message:
              "Version component of hierarchical string '\(string)' out of range."
          )
        }
        guard self.withVersion.components.count >= 2 else {
          throw .invalidSARIF(
            message:
              "Versioned hierarchical string '\(string)' has no components other than the version component."
          )
        }
        self.version = version
        self.withoutVersion = self.withVersion.removingLastComponent()
      } else {
        self.version = nil
        self.withoutVersion = self.withVersion
      }
    } else {
      self.version = nil
      self.withoutVersion = self.withVersion
    }
  }

  public init(fromComponents: String..., version: UInt32? = nil) {
    self.version = version
    self.withoutVersion = .init(fromComponents: fromComponents)
    self.withVersion =
      if let version {
        self.withoutVersion.appending("v\(version)")
      } else {
        self.withoutVersion
      }
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    try self.init(parsing: string)
  }

  public func hash(into hasher: inout Hasher) {
    // Only need the string with the version
    hasher.combine(withVersion)
  }

  public func encode(to encoder: any Encoder) throws {
    try self.withVersion.encode(to: encoder)
  }

  public var description: String { withVersion.string }

  private var versionString: String? {
    self.version.map { "v\($0)" }
  }

  public static func == (
    lhs: VersionedHierarchicalString, rhs: VersionedHierarchicalString
  )
    -> Bool
  {
    lhs.withVersion == rhs.withVersion
  }
}
