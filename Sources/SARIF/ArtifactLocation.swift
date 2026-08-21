import Foundation
internal import SARIFRecords

public struct ArtifactLocation: JSONRepresentable<ArtifactLocationRecord>,
  Hashable
{
  public struct DefaultSortKey: Comparable, SpaceshipComparable {
    private let uriBaseId: String?
    private let uri: URL

    fileprivate init(for location: ArtifactLocation) {
      self.uriBaseId = location.uriBaseId
      self.uri = location.uri
    }

    public static func < (_ lhs: Self, _ rhs: Self) -> Bool {
      (lhs <=> rhs) == true
    }

    internal static func <=> (_ lhs: Self, _ rhs: Self) -> Bool? {
      (lhs.uriBaseId <=> rhs.uriBaseId)
        ?? (lhs.uri.absoluteString <=> rhs.uri.relativeString)
    }
  }

  public var uri: URL
  public var uriBaseId: String?
  public var description: Message?

  public var defaultSortKey: DefaultSortKey { .init(for: self) }

  public init(uri: URL, uriBaseId: String?) {
    self.uri = uri
    self.uriBaseId = uriBaseId
  }

  /// Initialize the location for the definition of an artifact.
  internal init(
    from artifactLocationRecord: ArtifactLocationRecord,
    artifactIndex: ArrayIndex,
    sink: any ValidationSink
  ) throws {
    @Validating(sink: sink) var record = artifactLocationRecord

    if let recordIndex = record.index {
      if recordIndex != artifactIndex {
        try sink.recoverableError(
          "'index' value in 'artifactLocation' does not match the index of the enclosing 'artifact'."
        )
      }
    }

    // TODO: relative vs. absolute
    let uri = try $record.require(
      \.uri,
      message:
        "Missing 'uri' property on 'artifactLocation' for 'artifact' definition."
    )
    self.uri = uri
    self.uriBaseId = record.uriBaseId
    self.description = try record.description.map {
      try Message(from: $0, sink: sink)
    }
  }

  internal func toJSON() throws -> ArtifactLocationRecord {
    .init(
      uri: self.uri,
      uriBaseId: self.uriBaseId,
      index: nil,  // TODO: Optionally save the index, even though it's redundant.
      description: try self.description.toJSON()
    )
  }
}

internal struct ArtifactLoadMapTraits: DefinitionLoadMapTraits {
  typealias Definition = Artifact

  private let sink: any ValidationSink

  init(sink: any ValidationSink) {
    self.sink = sink
  }

  func keyNotFound(key: ArrayIndex) throws -> Never {
    try self.sink.fatalError("No Artifact found with index '\(key)'.")
  }
}

internal typealias ArtifactLoadMap = DefinitionLoadMap<ArtifactLoadMapTraits>

extension ArtifactLoadMap {
  convenience init(sink: any ValidationSink) {
    self.init(with: ArtifactLoadMapTraits(sink: sink))
  }
}

internal final class ArtifactReferenceResolver {
  fileprivate let artifacts: ArtifactLoadMap
  fileprivate let synthesizedArtifacts = SynthesizedDefinitionLoadMap<
    Artifact
  >()

  init(artifacts: ArtifactLoadMap) {
    self.artifacts = artifacts
  }
}

internal struct ArtifactLocationReferenceLoadContext {
  let artifactResolver: ArtifactReferenceResolver
}

internal struct ArtifactLocationReferenceSaveContext {
  let artifactMap: DefinitionSaveMap<Artifact, ArrayIndex>
}

public final class ArtifactLocationReference: JSONRepresentableWithContext<
  ArtifactLocationRecord
>
{
  public var artifact: Artifact
  public var description: Message?

  public init(to artifact: Artifact, description: Message? = nil) {
    self.artifact = artifact
    self.description = description
  }

  internal init(
    from artifactLocationRecord: ArtifactLocationRecord,
    sink: any ValidationSink,
    artifacts: ArtifactReferenceResolver
  ) throws {
    @Validating(sink: sink)
    var record = artifactLocationRecord

    if let index = record.index {
      self.artifact = try artifacts.artifacts.resolveDefinition(key: index)
      if let uri = record.uri {
        if let artifactUri = self.artifact.location?.uri {
          if uri != artifactUri {
            try sink.recoverableError(
              "The 'uri' property of the ArtifactLocation ('\(uri)') does not match the 'location.uri' property of the referenced Artifact ('\(artifactUri)')."
            )
          }
        } else {
          try sink.recoverableError(
            "The 'uri' property of the ArtifactLocation is '\(uri)', but the referenced artifact does not specify a 'location' property."
          )
        }
      }
      if let uriBaseId = record.uriBaseId {
        if let artifactUriBaseId = self.artifact.location?.uriBaseId {
          if uriBaseId != artifactUriBaseId {
            try sink.recoverableError(
              "The 'uriBaseId' property of the ArtifactLocation ('\(uriBaseId)') does not match the 'location.uriBaseId' property of the referenced Artifact ('\(artifactUriBaseId)')."
            )
          }
        } else {
          try sink.recoverableError(
            "The 'uriBaseId' property of the ArtifactLocation is '\(uriBaseId)', but the referenced artifact does not specify a 'location.uriBaseId' property."
          )
        }
      }
    } else {
      let uri = try $record.require(\.uri)
      self.artifact = artifacts.synthesizedArtifacts.synthesizeDefinition(
        key: .init(uri: uri, uriBaseId: record.uriBaseId))
    }
    self.description = try record.description.map {
      try Message(from: $0, sink: sink)
    }
  }

  internal func toJSON(with artifacts: DefinitionSaveMap<Artifact, ArrayIndex>)
    throws
    -> ArtifactLocationRecord
  {
    let description = try self.description.map { try $0.toJSON() }

    if let artifactIndex = artifacts.definitionIndex(of: self.artifact) {
      // Found an existing definition.
      // TODO: Verbosity
      return .init(
        uri: nil, uriBaseId: nil, index: artifactIndex, description: description
      )
    } else {
      // No index, so inline the data from the synthesized Artifact.
      return .init(
        uri: self.artifact.location?.uri,
        uriBaseId: self.artifact.location?.uriBaseId, index: nil,
        description: description)
    }
  }
}
