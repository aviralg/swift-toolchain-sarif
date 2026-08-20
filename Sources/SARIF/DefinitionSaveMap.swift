internal final class DefinitionSaveMap<Definition, Key>
where Definition: Hashable, Definition: AnyObject {
  private var definitionKeys: [Definition: Key] = [:]

  init() {
  }

  func add(_ definition: Definition, key: Key) {
    self.definitionKeys[definition] = key
  }

  func definitionIndex(of definition: Definition) -> Key? {
    self.definitionKeys[definition]
  }
}
