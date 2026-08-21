internal protocol MergeKeyProtocol<Object>: Hashable {
  associatedtype Object: MergeHashable where Object.MergeKey == Self

  typealias Context = Object.Context

  init(for object: Object, with context: Context) throws
}

internal protocol MergeHashable {
  associatedtype MergeKey: MergeKeyProtocol<Self>
  associatedtype Context

  func mergeKey(with context: Context) throws -> MergeKey
}

extension MergeHashable {
  func mergeKey(with context: Context) throws -> MergeKey {
    try .init(for: self, with: context)
  }
}
