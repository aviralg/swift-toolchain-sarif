internal protocol DefinitionLoadMapTraits {
  associatedtype Definition: Hashable, AnyObject
  associatedtype Key: Hashable

  func keyNotFound(key: Key) throws -> Never
}

internal final class DefinitionLoadMap<Traits: DefinitionLoadMapTraits> {
  typealias Key = Traits.Key
  typealias Definition = Traits.Definition

  internal let traits: Traits
  private var definitions: [Key: Definition] = [:]

  init(with traits: Traits) {
    self.traits = traits
  }

  func add(_ definition: Definition, key: Key) {
    self.definitions[key] = definition
  }

  func resolveDefinition(key: Key) throws -> Definition {
    if let definition = self.definitions[key] {
      return definition
    } else {
      try self.traits.keyNotFound(key: key)
    }
  }
}
