internal import SARIFRecords

internal struct LogicalLocationLoadTraits: DefinitionLoadMapTraits {
  typealias Definition = LogicalLocation

  fileprivate let sink: any ValidationSink

  init(sink: any ValidationSink) {
    self.sink = sink
  }

  func keyNotFound(key: ArrayIndex) throws -> Never {
    try self.sink.fatalError("No LogicalLocation found with index '\(key)'.")
  }
}

internal typealias LogicalLocationLoadMap = DefinitionLoadMap<
  LogicalLocationLoadTraits
>

extension LogicalLocationLoadMap {
  convenience init(sink: any ValidationSink) {
    self.init(with: LogicalLocationLoadTraits(sink: sink))
  }

  func validateAgainstDefinition<T: Equatable>(
    key: KeyPath<LogicalLocationRecord, T?>, reference: LogicalLocationRecord,
    definitionValue: T?
  ) throws {
    if let referenceValue = reference[keyPath: key] {
      guard referenceValue == definitionValue else {
        try self.traits.sink.fatalError(
          "'\(key)' property of LogicalLocation must match the value from the LogicalLocation object referenced by 'index'."
        )
      }
    }
  }

  func loadDefinition(from record: LogicalLocationRecord) throws
    -> LogicalLocation
  {
    try LogicalLocation(from: record, sink: self.traits.sink)
  }

  func resolveOrCreate(from record: LogicalLocationRecord) throws
    -> LogicalLocation
  {
    if let index = record.index {
      return try self.resolveDefinition(key: index)
    } else {
      // Create a new object.
      return try LogicalLocation(from: record, sink: self.traits.sink)
    }
  }
}

internal typealias LogicalLocationSaveMap = DefinitionSaveMap<
  LogicalLocation, ArrayIndex
>

extension DefinitionSaveMap
where Definition == LogicalLocation, Key == ArrayIndex {
  func makeReferenceJSON(to logicalLocation: LogicalLocation)
    -> LogicalLocationRecord
  {
    if let definitionIndex = self.definitionIndex(of: logicalLocation) {
      // Just need the index to refer to the definition
      return .init(
        index: definitionIndex, name: nil, fullyQualifiedName: nil,
        decoratedName: nil, kind: nil,
        parentIndex: nil)
    } else {
      // No cached definition, so need all the other properties.
      return makeDefinitionJSON(for: logicalLocation)
    }
  }

  func makeDefinitionJSON(for logicalLocation: LogicalLocation)
    -> LogicalLocationRecord
  {
    let parentIndex = logicalLocation.parent.map { parent in
      self.definitionIndex(of: parent)!  // TODO: Report error?
    }

    return .init(
      index: nil, name: logicalLocation.name,
      fullyQualifiedName: logicalLocation.fullyQualifiedName,
      decoratedName: logicalLocation.decoratedName, kind: logicalLocation.kind,
      parentIndex: parentIndex)
  }
}

public final class LogicalLocation: Hashable, Identifiable, JSONRepresentable<
  LogicalLocationRecord
>
{
  public let name: String?
  public let fullyQualifiedName: String?
  public let decoratedName: String?
  public let kind: String?
  public let parent: LogicalLocation?

  fileprivate init(
    from logicalLocationRecord: LogicalLocationRecord, sink: any ValidationSink
  )
    throws
  {
    self.name = logicalLocationRecord.name
    self.fullyQualifiedName = logicalLocationRecord.fullyQualifiedName
    self.decoratedName = logicalLocationRecord.decoratedName
    self.kind = logicalLocationRecord.kind
    self.parent = nil  // TODO: Parents
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }

  public static func == (lhs: LogicalLocation, rhs: LogicalLocation) -> Bool {
    lhs === rhs
  }
}
