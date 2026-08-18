fileprivate import Foundation
fileprivate import ImmutableJSON
fileprivate import SARIFRecords
import Testing

@Test
func emptyVersionedHierarchicalString() throws {
  let h = try VersionedHierarchicalString(parsing: "")
  #expect(h.version == nil)
  #expect(h.withVersion.components == [""])
  #expect(h.string == "")
}

@Test
func singleComponentWithoutVersion() throws {
  let h = try VersionedHierarchicalString(parsing: "component")
  #expect(h.withoutVersion.components == ["component"])
  #expect(h.withVersion.components == ["component"])
  #expect(h.version == nil)
}

@Test
func multipleComponentsWithoutVersion() throws {
  let h = try VersionedHierarchicalString(parsing: "foo/bar/baz")
  #expect(h.withoutVersion.components == ["foo", "bar", "baz"])
  #expect(h.withVersion.components == ["foo", "bar", "baz"])
  #expect(h.version == nil)
}

@Test
func singleComponentWithVersion() throws {
  // This should throw because there's no component other than version
  #expect(throws: SARIFError.self) {
    try VersionedHierarchicalString(parsing: "v1")
  }
}

@Test
func twoComponentsWithVersion() throws {
  let h = try VersionedHierarchicalString(parsing: "parent/v42")
  #expect(h.withoutVersion.components == ["parent"])
  #expect(h.withVersion.components == ["parent", "v42"])
  #expect(h.version == 42)
}

@Test
func multipleComponentsWithVersion() throws {
  let h = try VersionedHierarchicalString(parsing: "alpha/beta/gamma/v3")
  #expect(h.withoutVersion.components == ["alpha", "beta", "gamma"])
  #expect(h.withVersion.components == ["alpha", "beta", "gamma", "v3"])
  #expect(h.version == 3)
}

@Test
func versionZero() throws {
  let h = try VersionedHierarchicalString(parsing: "foo/bar/v0")
  #expect(h.version == 0)
  #expect(h.withoutVersion.components == ["foo", "bar"])
}

@Test
func largeVersionNumber() throws {
  let h = try VersionedHierarchicalString(parsing: "test/path/v99999")
  #expect(h.version == 99999)
}

@Test
func invalidVersionWithLeadingZero() throws {
  // v01 should not be valid (leading zeros not allowed except for v0)
  let h = try VersionedHierarchicalString(parsing: "component/v01")
  // This should treat "v01" as a regular component, not a version
  #expect(h.version == nil)
  #expect(h.withoutVersion.components == ["component", "v01"])
}

@Test
func versionComponentInMiddle() throws {
  // v1 in the middle should be treated as a regular component
  let h = try VersionedHierarchicalString(parsing: "foo/v1/bar")
  #expect(h.version == nil)
  #expect(h.withoutVersion.components == ["foo", "v1", "bar"])
}

@Test
func versionedStringRepresentation() throws {
  let h = try VersionedHierarchicalString(parsing: "alpha/beta/v5")
  #expect(h.description == "alpha/beta/v5")
}

@Test
func stringRepresentationWithoutVersion() throws {
  let h = try VersionedHierarchicalString(parsing: "foo/bar")
  #expect(h.description == "foo/bar")
}

@Test
func initFromComponentsWithoutVersion() throws {
  let h = VersionedHierarchicalString(fromComponents: "first", "second")
  #expect(h.withoutVersion.components == ["first", "second"])
  #expect(h.withVersion.components == ["first", "second"])
  #expect(h.version == nil)
}

@Test
func initFromComponentsWithVersion() throws {
  let h = VersionedHierarchicalString(
    fromComponents: "foo", "bar", "baz", version: 7)
  #expect(h.withoutVersion.components == ["foo", "bar", "baz"])
  #expect(h.withVersion.components == ["foo", "bar", "baz", "v7"])
  #expect(h.version == 7)
}

@Test
func initFromComponentsWithVersionZero() throws {
  let h = VersionedHierarchicalString(
    fromComponents: "alpha", "beta", version: 0)
  #expect(h.version == 0)
  #expect(h.withVersion.components.last == "v0")
}

@Test
func versionedHashableConformance() throws {
  let h1 = try VersionedHierarchicalString(parsing: "foo/bar/v2")
  let h2 = try VersionedHierarchicalString(parsing: "foo/bar/v2")
  let h3 = try VersionedHierarchicalString(parsing: "foo/bar/v3")
  let h4 = try VersionedHierarchicalString(parsing: "foo/bar")

  #expect(h1 == h2)
  #expect(h1 != h3)
  #expect(h1 != h4)

  let set: Set = [h1, h2, h3, h4]
  #expect(set.count == 3)
}

@Test
func equalityWithSameVersionDifferentComponents() throws {
  let h1 = try VersionedHierarchicalString(parsing: "foo/v1")
  let h2 = try VersionedHierarchicalString(parsing: "bar/v1")

  #expect(h1 != h2)
}

@Test
func codableRoundTrip() throws {
  let original = try VersionedHierarchicalString(parsing: "alpha/beta/v3")

  let data = try original.toJSONData()

  let decoded = try VersionedHierarchicalString.fromJSONData(data)

  #expect(decoded == original)
  #expect(decoded.version == 3)
  #expect(decoded.withoutVersion.components == ["alpha", "beta"])
}

@Test
func codableRoundTripWithoutVersion() throws {
  let original = try VersionedHierarchicalString(parsing: "foo/bar")

  let data = try original.toJSONData()

  let decoded = try VersionedHierarchicalString.fromJSONData(data)

  #expect(decoded == original)
  #expect(decoded.version == nil)
}

@Test
func versionedEmptyComponent() throws {
  let h = try VersionedHierarchicalString(parsing: "foo//bar/v1")
  #expect(h.version == 1)
  #expect(h.withVersion.components == ["foo", "", "bar", "v1"])
  #expect(h.string == "foo//bar/v1")
}

@Test
func versionedLeadingSlash() throws {
  let h = try VersionedHierarchicalString(parsing: "/foo/bar/v2")
  #expect(h.version == 2)
  #expect(h.withVersion.components == ["", "foo", "bar", "v2"])
  #expect(h.string == "/foo/bar/v2")
}

@Test
func versionedTrailingSlash() throws {
  let h = try VersionedHierarchicalString(parsing: "foo/bar/v1/")
  #expect(h.version == nil)  // The `v1` is not the last component.
  #expect(h.withVersion.components == h.withoutVersion.components)
  #expect(h.withVersion.components == ["foo", "bar", "v1", ""])
  #expect(h.string == "foo/bar/v1/")
}

@Test
func negativeVersionIsNotRecognized() throws {
  // v-1 should be treated as a regular component
  let h = try VersionedHierarchicalString(parsing: "foo/bar/v-1")
  #expect(h.version == nil)
  #expect(h.withoutVersion.components == ["foo", "bar", "v-1"])
}

@Test
func versionWithExtraCharacters() throws {
  // v1abc should be treated as a regular component
  let h = try VersionedHierarchicalString(parsing: "foo/bar/v1abc")
  #expect(h.version == nil)
  #expect(h.withVersion.components == ["foo", "bar", "v1abc"])
}

@Test
func justVIsNotAVersion() throws {
  let h = try VersionedHierarchicalString(parsing: "foo/bar/v")
  #expect(h.version == nil)
  #expect(h.withVersion.components == ["foo", "bar", "v"])
}

@Test
func versionTooLargeForUInt32() throws {
  // UInt32.max is 4294967295
  let tooLarge = "99999999999999999999"
  #expect(throws: SARIFError.self) {
    try VersionedHierarchicalString(parsing: "foo/bar/v\(tooLarge)")
  }
}

@Test
func maxValidVersion() throws {
  let h = try VersionedHierarchicalString(parsing: "foo/bar/v4294967295")
  #expect(h.version == 4_294_967_295)
}

@Test
func constructorConsistency() throws {
  let h1 = try VersionedHierarchicalString(parsing: "alpha/beta/v12")
  let h2 = VersionedHierarchicalString(
    fromComponents: "alpha", "beta", version: 12)

  #expect(h1 == h2)
  #expect(h1.version == h2.version)
  #expect(h1.withoutVersion == h2.withoutVersion)
  #expect(h1.withVersion == h2.withVersion)
}

@Test
func singleComponentNoVersionConstructor() throws {
  let h = VersionedHierarchicalString(fromComponents: "component")
  #expect(h.version == nil)
  #expect(h.withoutVersion.components == ["component"])
  #expect(h.withVersion.components == ["component"])
}
