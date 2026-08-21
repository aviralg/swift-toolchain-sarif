internal final class Merger<Object>
where Object: MergeableWithIdentity, Object.MergeState.Object == Object {
  private var first: Bool = true
  private var mergeState = Object.MergeState()

  func merge<Parent: AnyObject>(
    key: KeyPath<Parent, Object>, merger: inout PropertyMerger<Parent>
  )
    throws where Object.MergeState.Context == Void
  {
    try merge(key: key, merger: &merger, with: ())
  }

  func merge<Parent: AnyObject>(
    key: KeyPath<Parent, Object>, merger: inout PropertyMerger<Parent>,
    with context: Object.MergeState.Context
  ) throws {
    var propertyMerger = PropertyMerger(
      from: merger.input[keyPath: key], into: merger.output[keyPath: key],
      first: self.first,
      sink: merger.sink)
    try self.mergeState.merge(merger: &propertyMerger, with: context)
    self.first = false
  }
}

internal final class ValueMerger<Value>
where Value: MergeableValue, Value.MergeState.Value == Value {
  private var first: Bool = true
  private var mergeState = Value.MergeState()

  func merge<Parent>(
    key: WritableKeyPath<Parent, Value>, merger: inout PropertyMerger<Parent>,
    with context: Value.MergeState.Context
  ) throws {
    var propertyMerger = PropertyMerger(
      from: merger.input[keyPath: key], into: merger.output[keyPath: key],
      first: self.first,
      sink: merger.sink)
    try self.mergeState.merge(merger: &propertyMerger, with: context)
    merger.output[keyPath: key] = propertyMerger.output
    self.first = false
  }
}
