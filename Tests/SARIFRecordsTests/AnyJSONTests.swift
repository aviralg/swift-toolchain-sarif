import Testing

@testable fileprivate import SARIFRecords

@Test
func decodeNil() throws {
  let actual = try AnyJSON.fromJSONString("null")
  #expect(actual == .null)
}

@Test
func decodeBool() throws {
  let actualTrue = try AnyJSON.fromJSONString("true")
  #expect(actualTrue == .boolean(true))

  let actualFalse = try AnyJSON.fromJSONString("false")
  #expect(actualFalse == .boolean(false))
}

@Test
func decodeNumber() throws {
  for (json, value) in [("0", 0.0), ("-1", -1.0), ("1.5", 1.5)] {
    let actual = try AnyJSON.fromJSONString(json)
    #expect(actual == .number(value))
  }
}

@Test
func decodeString() throws {
  for (json, value) in [("", ""), ("text", "text"), ("escape\\n", "escape\n")] {
    let actual = try AnyJSON.fromJSONString("\"\(json)\"")
    #expect(actual == .string(value))
  }
}

@Test
func decodeObject() throws {
  let actual = try AnyJSON.fromJSONString(
    """
    {
        "null": null,
        "bool": true,
        "number": 3.25,
        "string": "text"
    }
    """)

  let expected: AnyJSON = .object([
    "null": .null,
    "bool": .boolean(true),
    "number": .number(3.25),
    "string": .string("text"),
  ])

  #expect(actual == expected)
}

@Test
func decodeArray() throws {
  let actual = try AnyJSON.fromJSONString(
    """
    [
        null,
        true,
        3.25,
        "text"
    ]
    """)

  let expected: AnyJSON = .array([
    .null,
    .boolean(true),
    .number(3.25),
    .string("text"),
  ])

  #expect(actual == expected)
}
