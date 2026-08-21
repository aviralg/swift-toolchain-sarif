public import Foundation

extension ArtifactLocation {
  public func mappingURL(mappings: [URLBaseMapping]) -> ArtifactLocation {
    if self.uriBaseId != nil {
      // Already have a base
      return self
    }
    for mapping in mappings {
      if let relativeURL = self.uri.relativeTo(base: mapping.prefix) {
        return .init(uri: relativeURL, uriBaseId: mapping.baseId)
      }
    }

    return self
  }
}

public struct URLBaseMapping {
  public let baseId: String
  public let prefix: URL

  public init(baseId: String, prefix: URL) {
    self.baseId = baseId
    self.prefix = prefix
  }
}

extension URL {
  fileprivate func relativeTo(base: URL) -> URL? {
    guard self.scheme == base.scheme else {
      return nil
    }

    let destComponents = self.pathComponents
    let baseComponents = base.pathComponents
    for (destComponent, baseComponent) in zip(destComponents, baseComponents) {
      guard destComponent == baseComponent else {
        return nil
      }
    }

    let relativePath = self.pathComponents.dropFirst(baseComponents.count)
      .joined(separator: "/")
    return URL(string: relativePath)
  }
}

extension SARIFLog {
  public func mapURLs(with mappings: [URLBaseMapping]) {
    self.runs.forEach { run in
      run.artifacts.forEach { artifact in
        artifact.location = artifact.location.map { location in
          if location.uriBaseId != nil {
            return location
          }
          for mapping in mappings {
            if let relativeURL = location.uri.relativeTo(base: mapping.prefix) {
              return .init(uri: relativeURL, uriBaseId: mapping.baseId)
            }
          }

          return location
        }
      }
    }
  }
}
