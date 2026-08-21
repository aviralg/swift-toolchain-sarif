internal protocol SynthesizableDefinition: AnyObject {
  associatedtype Key: Hashable

  init(synthesizedFromKey: Key)
}

internal final class SynthesizedDefinitionLoadMap<
  Definition: SynthesizableDefinition
> {
  typealias Key = Definition.Key

  private var definitionsByKey: [Key: Definition] = [:]

  func synthesizeDefinition(key: Key) -> Definition {
    if let definition = self.definitionsByKey[key] {
      return definition
    } else {
      let definition = Definition(synthesizedFromKey: key)
      self.definitionsByKey[key] = definition
      return definition
    }
  }
}
