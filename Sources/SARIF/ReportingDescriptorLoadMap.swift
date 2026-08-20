import Foundation
internal import SARIFRecords

internal protocol DualIndexTraits {
  associatedtype Element: AnyObject

  func duplicateGuid(guid: UUID) throws -> Never
  func indexNotFound(index: ArrayIndex) throws -> Never
  func guidNotFound(guid: UUID) throws -> Never
  func guidMismatch(index: ArrayIndex, guid: UUID) throws -> Never
  func noKeySpecified() throws -> Element
}

internal final class DualIndex<Traits: DualIndexTraits> {
  private let traits: Traits
  private var byIndex: [Traits.Element] = []
  private var byGuid: [UUID: Traits.Element] = [:]

  fileprivate init(with traits: Traits) {
    self.traits = traits
  }

  internal func append(_ element: Traits.Element, guid: UUID?) throws {
    try indexByGuid(element, guid: guid)
    self.byIndex.append(element)
  }

  fileprivate func addWithoutIndex(_ element: Traits.Element, guid: UUID) throws
  {
    try indexByGuid(element, guid: guid)
  }

  fileprivate func lookup(index: ArrayIndex?, guid: UUID?) throws
    -> Traits.Element
  {
    guard (index != nil) || (guid != nil) else {
      return try self.traits.noKeySpecified()
    }

    var elementByIndex: Traits.Element? = nil
    if let index {
      guard self.byIndex.indices.contains(Int(index)) else {
        try self.traits.indexNotFound(index: index)
      }

      elementByIndex = self.byIndex[Int(index)]
    }

    var elementByGuid: Traits.Element? = nil
    if let guid {
      elementByGuid = self.byGuid[guid]
      guard elementByGuid != nil else {
        try self.traits.guidNotFound(guid: guid)
      }
    }

    guard
      (elementByIndex == nil) || (elementByGuid == nil)
        || (elementByIndex === elementByGuid)
    else {
      try self.traits.guidMismatch(index: index!, guid: guid!)
    }

    return elementByIndex ?? elementByGuid!
  }

  private func indexByGuid(_ element: Traits.Element, guid: UUID?) throws {
    if let guid {
      guard self.byGuid.updateValue(element, forKey: guid) == nil else {
        try self.traits.duplicateGuid(guid: guid)
      }
    }
  }
}

internal final class ReportingDescriptorLoadMap<Kind>
where Kind: ReportingDescriptorKind {
  typealias Descriptor = ReportingDescriptor<Kind>

  internal struct DescriptorIndexTraits: DualIndexTraits {
    private let sink: any ValidationSink

    fileprivate init(sink: any ValidationSink) {
      self.sink = sink
    }

    func duplicateGuid(guid: UUID) throws -> Never {
      try self.sink.fatalError(
        "Multiple ReportingDescriptors with GUID '\(guid)'.")
    }

    func indexNotFound(index: ArrayIndex) throws -> Never {
      try self.sink.fatalError(
        "No ReportingDescriptor found for index '\(index)'.")
    }

    func guidNotFound(guid: UUID) throws -> Never {
      try self.sink.fatalError(
        "No ReportingDescriptor found for GUID '\(guid)'.")
    }

    func guidMismatch(index: ArrayIndex, guid: UUID) throws -> Never {
      try self.sink.fatalError(
        "Index '\(index)' and GUID '\(guid)' refer to different ReportingDescriptors."
      )
    }

    func noKeySpecified() throws -> Descriptor {
      try self.sink.fatalError(
        "ReportingDescriptorReference must specify at least one of 'index' and 'guid'."
      )
    }
  }

  internal typealias DescriptorIndex = DualIndex<DescriptorIndexTraits>

  private struct ToolComponentIndexTraits: DualIndexTraits {
    private let driver: DescriptorIndex
    private let sink: any ValidationSink

    fileprivate init(driver: DescriptorIndex, sink: any ValidationSink) {
      self.driver = driver
      self.sink = sink
    }

    func duplicateGuid(guid: UUID) throws -> Never {
      try self.sink.fatalError("Multiple ToolComponents with GUID '\(guid)'.")
    }

    func indexNotFound(index: ArrayIndex) throws -> Never {
      try self.sink.fatalError("No ToolComponent found for index '\(index)'.")
    }

    func guidNotFound(guid: UUID) throws -> Never {
      try self.sink.fatalError("No ToolComponent found for GUID '\(guid)'.")
    }

    func guidMismatch(index: ArrayIndex, guid: UUID) throws -> Never {
      try self.sink.fatalError(
        "Index '\(index)' and GUID '\(guid)' refer to different ToolComponents."
      )
    }

    func noKeySpecified() -> DescriptorIndex {
      // Default to the driver if no index or GUID is specified.
      self.driver
    }
  }

  private typealias ToolComponentIndex = DualIndex<ToolComponentIndexTraits>

  private let sink: any ValidationSink
  internal private(set) var driver: DescriptorIndex
  private var toolComponentIndex: ToolComponentIndex

  internal init(driverGuid: UUID?, sink: any ValidationSink) throws {
    self.sink = sink
    self.driver = .init(with: DescriptorIndexTraits(sink: sink))
    self.toolComponentIndex = .init(
      with: ToolComponentIndexTraits(driver: self.driver, sink: sink))
    if let driverGuid {
      try self.toolComponentIndex.addWithoutIndex(self.driver, guid: driverGuid)
    }
  }

  internal func addExtension(guid: UUID?) throws -> DescriptorIndex {
    let descriptorIndex = DescriptorIndex(
      with: DescriptorIndexTraits(sink: self.sink))
    try self.toolComponentIndex.append(descriptorIndex, guid: guid)

    return descriptorIndex
  }

  internal func resolveDescriptor(
    reference: ReportingDescriptorReferenceRecord?, shorthandIndex: ArrayIndex?
  ) throws -> Descriptor {
    let toolComponent = try resolveToolComponent(for: reference?.toolComponent)
    if let shorthandIndex, let referenceIndex = reference?.index {
      guard shorthandIndex == referenceIndex else {
        try self.sink.fatalError(
          "'ruleIndex' property of Result must match 'rule.index' property.")
      }
    }

    return try toolComponent.lookup(
      index: shorthandIndex ?? reference?.index, guid: reference?.guid)
  }

  private func resolveToolComponent(
    for reference: ToolComponentReferenceRecord?
  ) throws
    -> DescriptorIndex
  {
    try self.toolComponentIndex.lookup(
      index: reference?.index, guid: reference?.guid)
  }
}

internal typealias RuleLoadMap = ReportingDescriptorLoadMap<RuleDescriptorKind>
