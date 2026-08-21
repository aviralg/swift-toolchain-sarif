internal import SARIFRecords

public struct MultiFormatMessageString: Hashable, JSONRepresentable<
  MultiformatMessageStringRecord
>
{
  public let text: String
  public let markdown: String?

  public init(text: String, markdown: String? = nil) {
    self.text = text
    self.markdown = markdown
  }

  internal init(
    from multiFormatMessageStringRecord: MultiformatMessageStringRecord,
    sink: any ValidationSink
  ) throws {
    self.text = multiFormatMessageStringRecord.text
    self.markdown = multiFormatMessageStringRecord.markdown
  }

  internal var mergeKey: MultiFormatMessageString { self }

  internal func toJSON() -> MultiformatMessageStringRecord {
    .init(text: text, markdown: markdown)
  }
}
