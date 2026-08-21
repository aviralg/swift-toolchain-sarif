import OrderedCollections
public import SARIFRecords

public struct DefaultWarning: DefaultValueProvider {
  public static let defaultValue: ResultLevel = .warning
}

//@Mergeable
public struct ReportingConfiguration: JSONRepresentable<
  ReportingConfigurationRecord
>
{
  public var enabled: Bool?
  public var level: ResultLevel?
  public var rank: Float? = nil
  @WithDefaultValue<DefaultEmptyOrderedDictionary>
  public var parameters: OrderedDictionary<HierarchicalString, AnyJSON>

  internal init(
    from reportingConfigurationRecord: ReportingConfigurationRecord,
    sink: any ValidationSink
  ) throws {
    @Validating(sink: sink) var record = reportingConfigurationRecord

    self.rank = record.rank
    self.$parameters = record.parameters.map({ $0.orderedDictionary })
    self.enabled = record.enabled
    self.level = record.level
  }

  internal func toJSON() throws -> ReportingConfigurationRecord {
    .init(
      enabled: self.enabled,
      level: self.level,
      rank: self.rank,
      parameters: try self.parameters.ifNotEmpty?.toJSON()
    )
  }
}
