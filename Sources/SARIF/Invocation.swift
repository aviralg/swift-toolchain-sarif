public import SARIFRecords

public final class Invocation: JSONRepresentable<InvocationRecord> {
  public var executionSuccessful: Bool
  public var properties: PropertyBag

  internal init(
    from record: InvocationRecord, propertyProviders: PropertyProviders,
    sink: any ValidationSink
  ) throws {
    self.executionSuccessful = record.executionSuccessful
    self.properties = try .init(
      from: record.properties ?? [:], providers: propertyProviders)
  }

  func toJSON() throws -> InvocationRecord {
    .init(
      executionSuccessful: self.executionSuccessful,
      properties: try self.properties.toJSON(),
    )
  }
}
