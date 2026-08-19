package import Foundation

extension Bundle {
  package func resourceDirectory() throws -> URL {
    let resourcePath = URL(
      filePath: self.resourcePath!, directoryHint: .isDirectory)
    return resourcePath.appending(
      path: "Resources", directoryHint: .isDirectory)
  }

  package func resourceFile(named name: String) throws -> URL {
    try resourceDirectory().appending(path: name, directoryHint: .notDirectory)
  }
}
