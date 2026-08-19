fileprivate import SARIFRecords
import Testing

@Test
func emptyHierarchicalString() {
  let h = HierarchicalString(parsing: "")
  #expect(h.components == [""])
}

@Test
func singleComponentHierarchicalString() {
  let h = HierarchicalString(parsing: "foo")
  #expect(h.components == ["foo"])
}

@Test
func multipleComponentHierarchicalString() {
  let h = HierarchicalString(parsing: "foo/bar/baz")
  #expect(h.components == ["foo", "bar", "baz"])
}

@Test
func twoComponentHierarchicalString() {
  let h = HierarchicalString(parsing: "parent/child")
  #expect(h.components == ["parent", "child"])
  #expect(h.string == "parent/child")
}

@Test
func stringRepresentation() {
  let h = HierarchicalString(parsing: "one/two/three")
  #expect(h.string == "one/two/three")
  #expect(h.description == "one/two/three")
}

@Test
func emptyComponent() throws {
  let h = HierarchicalString(parsing: "foo//bar")
  #expect(h.components == ["foo", "", "bar"])
  #expect(h.string == "foo//bar")
}

@Test
func leadingSlash() {
  let h = HierarchicalString(parsing: "/foo/bar")
  #expect(h.components == ["", "foo", "bar"])
  #expect(h.string == "/foo/bar")
}

@Test
func trailingSlash() {
  let h = HierarchicalString(parsing: "foo/bar/")
  #expect(h.components == ["foo", "bar", ""])
  #expect(h.string == "foo/bar/")
}

@Test
func initFromComponentsArray() throws {
  let h = HierarchicalString(fromComponents: ["alpha", "beta", "gamma"])
  #expect(h.components == ["alpha", "beta", "gamma"])
  #expect(h.string == "alpha/beta/gamma")
}

@Test
func initFromComponentsVariadic() throws {
  let h = HierarchicalString(fromComponents: "one", "two", "three")
  #expect(h.components == ["one", "two", "three"])
  #expect(h.string == "one/two/three")
}

@Test
func appendComponent() {
  let h1 = HierarchicalString(parsing: "foo/bar")
  let h2 = h1.appending("baz")

  #expect(h1.components == ["foo", "bar"])
  #expect(h2.components == ["foo", "bar", "baz"])
  #expect(h2.string == "foo/bar/baz")
}

@Test
func appendToSingleComponent() {
  let h1 = HierarchicalString(parsing: "root")
  let h2 = h1.appending("child")

  #expect(h1.components == ["root"])
  #expect(h2.components == ["root", "child"])
}

@Test
func removeLastComponent() {
  let h1 = HierarchicalString(parsing: "foo/bar/baz")
  let h2 = h1.removingLastComponent()

  #expect(h1.components == ["foo", "bar", "baz"])
  #expect(h2.components == ["foo", "bar"])
  #expect(h2.string == "foo/bar")
}

@Test
func removeLastComponentMultipleTimes() {
  let h1 = HierarchicalString(parsing: "a/b/c/d")
  let h2 = h1.removingLastComponent()
  let h3 = h2.removingLastComponent()

  #expect(h3.components == ["a", "b"])
  #expect(h3.string == "a/b")
}

@Test
func hashableConformance() {
  let h1 = HierarchicalString(parsing: "foo/bar")
  let h2 = HierarchicalString(parsing: "foo/bar")
  let h3 = HierarchicalString(parsing: "foo/baz")

  #expect(h1 == h2)
  #expect(h1 != h3)

  let set: Set = [h1, h2, h3]
  #expect(set.count == 2)
}

@Test
func specialCharactersInComponents() {
  let h = HierarchicalString(parsing: "hello-world/test_123/foo.bar")
  #expect(h.components == ["hello-world", "test_123", "foo.bar"])
}

@Test
func unicodeInComponents() {
  let h = HierarchicalString(parsing: "café/日本語/emoji😀")
  #expect(h.components == ["café", "日本語", "emoji😀"])
  #expect(h.string == "café/日本語/emoji😀")
}
