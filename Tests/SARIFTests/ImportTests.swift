import Foundation
import ImmutableJSON
import SARIF
import SARIFRecords
import SARIFTestUtilities
import Testing

func readFile(named name: String) throws -> Data {
  try Data(contentsOf: try Bundle.module.resourceFile(named: name))
}

func readJSON<T: Decodable>(_ type: T.Type, named name: String) throws -> T {
  let data = try readFile(named: name)
  return try T.fromJSONData(data)
}

func loadSarifLog(from fileName: String, sink: any ValidationSink) throws
  -> SARIFLog
{
  let logRecord = try readJSON(SARIFLogRecord.self, named: fileName)

  return try SARIFLog(from: logRecord, sink: sink)
}

@Test("Basic import")
func basicImport() throws {
  let log = try readJSON(SARIFLogRecord.self, named: "cpp.sarif")

  #expect(log.version == "2.1.0")
}

@Test("Clang import")
func clangImport() throws {
  let log = try readJSON(SARIFLogRecord.self, named: "test.sarif")

  #expect(log.version == "2.1.0")
}

@Test("Clang semantic import")
func clangSemanticImport() throws {
  let log = try readJSON(SARIFLog.self, named: "test.sarif")

  #expect(log.version == .v2_1_0)
  #expect(log.runs[0].artifacts[0].length == 99)
  #expect(
    log.runs[0].results[0].locations[0].physicalLocation?.artifactLocation?
      .artifact
      === log.runs[0].artifacts[0])
  #expect(
    log.runs[0].results[0].locations[0].physicalLocation?.region?.textRegion
      == TextRegion(line: 3, startColumn: 16, endColumn: 18))
}

@Test("Clang semantic import 2")
func clangSemanticImport2() throws {
  let log = try readJSON(SARIFLog.self, named: "test2.sarif")

  #expect(log.version == .v2_1_0)
}
