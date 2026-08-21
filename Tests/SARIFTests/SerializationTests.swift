import Foundation
import SARIF
import SARIFRecords
import Testing

func difference(expected: String, actual: String) -> String? {
  let expectedLines = expected.split(
    separator: "\n", omittingEmptySubsequences: false)
  let actualLines = actual.split(
    separator: "\n", omittingEmptySubsequences: false)

  let diff = actualLines.difference(from: expectedLines)
  if diff.isEmpty {
    return nil
  } else {
    var diffLines = [""]  // Add an empty line at the beginning to make the Xcode failure UI look cleaner.
    var expectedLineIndex = 0
    var actualLineIndex = 0
    var nextRemovalIndex = 0
    var nextInsertionIndex = 0
    while (expectedLineIndex < expectedLines.count)
      || (actualLineIndex < actualLines.count)
    {
      if nextRemovalIndex < diff.removals.count,
        case .remove(let offset, let removedLine, _) = diff.removals[
          nextRemovalIndex],
        offset == expectedLineIndex
      {
        // We have a removal.
        diffLines.append("- \(removedLine)")
        nextRemovalIndex += 1
        expectedLineIndex += 1
      } else if nextInsertionIndex < diff.insertions.count,
        case .insert(let offset, let insertedLine, _) = diff.insertions[
          nextInsertionIndex],
        offset == actualLineIndex
      {
        // We have an insertion.
        diffLines.append("+ \(insertedLine)")
        nextInsertionIndex += 1
        actualLineIndex += 1
      } else {
        diffLines.append("  \(expectedLines[expectedLineIndex])")
        expectedLineIndex += 1
        actualLineIndex += 1
      }
    }

    return diffLines.joined(separator: "\n") + "\n"  // Add a final newline
  }
}

package func expectJSON(
  expected: some Encodable, actual: some Encodable,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  let expectedText = try! expected.toJSONString()
  let actualText = try! actual.toJSONString()
  let diff = difference(expected: expectedText, actual: actualText)
  #expect(diff == nil, sourceLocation: sourceLocation)
}

@Test
func serializeEmpty() throws {
  let actual = SARIFLog()
  let expected = SARIFLogRecord(runs: [])
  expectJSON(expected: expected, actual: actual)
}

@Test
func serializeEmptyRun() throws {
  let actual = SARIFLog()
  actual.addRun(tool: Tool(driverName: "driver"))
  let expected = SARIFLogRecord(runs: [
    RunRecord(tool: ToolRecord(driver: ToolComponentRecord(name: "driver")))
  ])
  expectJSON(expected: expected, actual: actual)
}

@Test
func serializeWithDriverRules() throws {
  let actual = SARIFLog()
  let driver = ToolComponent(named: "driver")
  let rule1 = driver.addRule(id: "Don'tDoThat")
  let rule2 = driver.addRule(id: "Don'tDoThatEither")

  let run = actual.addRun(tool: Tool(driver: driver))

  run.addResult(rule: rule1, messageText: "Don't do that!")
  run.addResult(rule: rule1, messageText: "Don't do that!")
  run.addResult(rule: rule2, messageText: "Don't do that either!")

  let expected = SARIFLogRecord(
    runs: [
      .init(
        tool: .init(
          driver: .init(
            name: "driver",
            rules: [
              .init(id: rule1.id),
              .init(id: rule2.id),
            ]
          )
        ),
        results: [
          .init(
            message: .init(text: "Don't do that!"),
            ruleId: .init(fromComponents: rule1.id),
            ruleIndex: 0
          ),
          .init(
            message: .init(text: "Don't do that!"),
            ruleId: .init(fromComponents: rule1.id),
            ruleIndex: 0
          ),
          .init(
            message: .init(text: "Don't do that either!"),
            ruleId: .init(fromComponents: rule2.id),
            ruleIndex: 1
          ),
        ]
      )
    ]
  )

  expectJSON(expected: expected, actual: actual)
}
