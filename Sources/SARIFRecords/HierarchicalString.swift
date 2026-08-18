/// A SARIF [hierarchical string](https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790689),
/// consisting of a slash-separated sequence of one or more string components. Any component may be an empty string.
public struct HierarchicalString: Codable, Hashable, Sendable,
  CustomStringConvertible,
  ExpressibleByStringLiteral
{
  public let components: [String]
  public var string: String { components.joined(separator: "/") }

  public init(stringLiteral string: String) {
    self.init(parsing: string)
  }

  public init(parsing string: String) {
    self.init(
      fromComponents: string.split(
        separator: "/", omittingEmptySubsequences: false
      ).map {
        String($0)
      })
  }

  public init(fromComponents components: [String]) {
    precondition(!components.isEmpty)
    self.components = components
  }

  public init(fromComponents components: String...) {
    self.init(fromComponents: components)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    self.init(parsing: string)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.string)
  }

  public var description: String { self.string }

  public func appending(_ component: String) -> HierarchicalString {
    var components = self.components
    components.append(component)
    return .init(fromComponents: components)
  }

  public func removingLastComponent() -> HierarchicalString {
    precondition(self.components.count > 1)
    var components = self.components
    components.removeLast()
    return .init(fromComponents: components)
  }
}
