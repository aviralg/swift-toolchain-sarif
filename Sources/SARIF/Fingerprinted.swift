public import SARIFRecords

public protocol Fingerprinted {
  func getPartialFingerprints() -> Fingerprints
}
