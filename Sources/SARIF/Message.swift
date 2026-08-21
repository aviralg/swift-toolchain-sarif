public import SARIFRecords

public struct Message: JSONRepresentable<MessageRecord>, Hashable {
  public var defaultMessage: MultiFormatMessageString?
  public var id: MessageID?
  public var arguments: [String]

  public init(
    text: String, markdown: String? = nil, id: MessageID? = nil,
    arguments: [String] = []
  ) {
    self.init(
      MultiFormatMessageString(text: text, markdown: markdown), id: id,
      arguments: arguments)
  }

  public init(
    _ defaultMessage: MultiFormatMessageString, id: MessageID? = nil,
    arguments: [String] = []
  ) {
    self.defaultMessage = defaultMessage
    self.id = id
    self.arguments = arguments
  }

  public init(id: MessageID, arguments: [String] = []) {
    self.defaultMessage = nil
    self.id = id
    self.arguments = arguments
  }

  internal init(from messageRecord: MessageRecord, sink: any ValidationSink)
    throws
  {
    @Validating(sink: sink)
    var record = messageRecord

    if let text = record.text {
      self.defaultMessage = MultiFormatMessageString(
        text: text, markdown: messageRecord.markdown)
      self.id = record.id  // Can be nil.
    } else {
      self.defaultMessage = nil
      self.id = try $record.require(\.id)
    }
    // TODO: Validate `id`.
    self.arguments = messageRecord.arguments ?? []
  }

  internal func toJSON() throws -> MessageRecord {
    .init(
      id: self.id,
      text: self.defaultMessage?.text.toJSON(),
      markdown: try self.defaultMessage?.markdown.toJSON(),
      arguments: try self.arguments.ifNotEmpty?.toJSON()
    )
  }
}
