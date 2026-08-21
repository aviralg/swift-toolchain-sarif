internal import SARIFRecords

public struct PhysicalLocation: JSONRepresentableWithContext<
  PhysicalLocationRecord
>
{
  public struct DefaultSortKey: Comparable, SpaceshipComparable {
    private let artifactLocation: ArtifactLocation.DefaultSortKey?
    private let region: Region.DefaultSortKey?

    fileprivate init(for location: PhysicalLocation) {
      self.artifactLocation =
        location.artifactLocation?.artifact.location?.defaultSortKey
      self.region = location.region?.defaultSortKey
    }

    public static func < (_ lhs: Self, _ rhs: Self) -> Bool {
      (lhs <=> rhs) == true
    }

    internal static func <=> (_ lhs: Self, _ rhs: Self) -> Bool? {
      (lhs.artifactLocation <=> rhs.artifactLocation)
        ?? (lhs.region <=> rhs.region)
    }
  }

  public var artifactLocation: ArtifactLocationReference?
  public var region: Region?
  public var contextRegion: Region?
  public var defaultSortKey: DefaultSortKey { .init(for: self) }

  public init(
    artifactLocation: ArtifactLocationReference? = nil, region: Region? = nil,
    contextRegion: Region? = nil
  ) {
    self.artifactLocation = artifactLocation
    self.region = region
    self.contextRegion = contextRegion
  }

  internal init(
    from physicalLocationRecord: PhysicalLocationRecord,
    sink: any ValidationSink,
    artifacts: ArtifactReferenceResolver
  ) throws {
    @Validating(sink: sink) var record = physicalLocationRecord

    self.artifactLocation = try .init(
      from: try $record.require(\.artifactLocation), sink: sink,
      artifacts: artifacts)
    if record.region == nil {
      try $record.forbid(
        \.contextRegion,
        message: "'contextRegion' not allowed unless 'region' is specified.")
    }
    self.region = try record.region.map { try .init(from: $0, sink: sink) }
    self.contextRegion = try record.contextRegion.map {
      try .init(from: $0, sink: sink)
    }

    try $record.forbid(\.address, message: "'address' NYI.")
  }

  internal func toJSON(with artifacts: DefinitionSaveMap<Artifact, ArrayIndex>)
    throws
    -> PhysicalLocationRecord
  {
    .init(
      artifactLocation: try self.artifactLocation.toJSON(with: artifacts),
      region: try self.region.toJSON(),
      contextRegion: try self.contextRegion.toJSON(),
      address: nil  // FIXME
    )
  }
}
