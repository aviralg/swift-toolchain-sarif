internal protocol MergeStateProtocolWithContext<Object> {
  associatedtype Object: MergeableWithIdentity where Object.MergeState == Self

  typealias Context = Object.Context

  init()

  mutating func merge(
    merger: inout PropertyMerger<Object>, with context: Context) throws
}

internal protocol ValueMergeStateProtocolWithContext<Value> {
  associatedtype Value: MergeableValue where Value.MergeState == Self

  typealias Context = Value.Context

  init()

  mutating func merge(
    merger: inout PropertyMerger<Value>, with context: Context) throws
}

internal protocol MergeStateProtocol<Object>: MergeStateProtocolWithContext
where Context == Void {
  mutating func merge(merger: inout PropertyMerger<Object>) throws
}

extension MergeStateProtocol {
  mutating func merge(
    merger: inout PropertyMerger<Object>, with context: Context
  ) throws {
    try merge(merger: &merger)
  }
}

internal protocol MergeableWithIdentity: AnyObject, MergeHashable {
  associatedtype MergeState: MergeStateProtocolWithContext
  where MergeState.Object == Self
}

internal protocol MergeableValue: MergeHashable {
  associatedtype MergeState: ValueMergeStateProtocolWithContext
  where MergeState.Value == Self
}
