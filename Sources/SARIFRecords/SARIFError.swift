public enum SARIFError: Error {
  case unsupportedVersion(version: String)
  case invalidSARIF(message: String)
}
