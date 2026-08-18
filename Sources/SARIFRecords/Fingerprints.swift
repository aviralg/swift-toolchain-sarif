public typealias Fingerprints = JSONDictionary<
  VersionedHierarchicalString, String
>

extension Fingerprints {
  public static let empty: Fingerprints = [:]
}
