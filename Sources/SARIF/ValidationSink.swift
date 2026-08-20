public import SARIFRecords

public protocol ValidationSink {
  func warning(_ message: String)
  func recoverableError(_ message: String) throws
  func fatalError(_ message: String) throws -> Never
}

public final class CollectingValidationSink: ValidationSink {
  private let sink: any ValidationSink
  private var anyErrors = false

  fileprivate init(sink: any ValidationSink) {
    self.sink = sink
  }

  public func warning(_ message: String) {
    self.sink.warning(message)
  }

  public func recoverableError(_ message: String) throws {
    try self.sink.recoverableError(message)
    self.anyErrors = true
  }

  public func fatalError(_ message: String) throws -> Never {
    try self.sink.fatalError(message)
  }

  fileprivate func reportFatalOnError(_ message: @autoclosure () -> String)
    throws
  {
    if self.anyErrors {
      try self.sink.fatalError(message())
    }
  }
}

extension ValidationSink {
  public func fatalErrorIfAnyErrors<Result>(
    _ message: @autoclosure () -> String,
    execute: (any ValidationSink) throws -> Result
  ) throws -> Result {
    let sink = CollectingValidationSink(sink: self)
    let result = try execute(sink)
    try sink.reportFatalOnError(message())

    return result
  }
}

@propertyWrapper
internal struct Validating<T> {
  internal let sink: any ValidationSink
  internal private(set) var value: T

  init(wrappedValue value: T, sink: any ValidationSink) {
    self.sink = sink
    self.value = value
  }

  var wrappedValue: T {
    get { self.value }
    set { self.value = newValue }
  }

  var projectedValue: Self { self }

  func require<V>(_ key: KeyPath<T, V?>) throws(SARIFError) -> V {
    let value = self.value[keyPath: key]
    guard let value else {
      throw SARIFError.invalidSARIF(
        message: "'\(T.self)' object is missing required property '\(key)'.")
    }

    return value
  }

  func require<V>(_ key: KeyPath<T, V?>, message: String) throws(SARIFError)
    -> V
  {
    let value = self.value[keyPath: key]
    guard let value else {
      throw SARIFError.invalidSARIF(message: message)
    }

    return value
  }

  func forbid<V>(_ key: KeyPath<T, V?>) throws(SARIFError) {
    let value = self.value[keyPath: key]
    guard value == nil else {
      throw SARIFError.invalidSARIF(
        message: "'\(T.self)' object contains forbidden property '\(key)'.")
    }
  }

  func forbid<V>(_ key: KeyPath<T, V?>, message: String) throws(SARIFError) {
    let value = self.value[keyPath: key]
    guard value == nil else {
      throw SARIFError.invalidSARIF(message: message)
    }
  }
}

public struct StdOutValidationSink: ValidationSink {
  public init() {
  }

  public func warning(_ message: String) {
    print("Warning: \(message)")
  }

  public func recoverableError(_ message: String) throws(SARIFError) {
    print("Recoverable Error: \(message)")
  }

  public func fatalError(_ message: String) throws(SARIFError) -> Never {
    print("Fatal Error: \(message)")
    throw .invalidSARIF(message: message)
  }
}

public struct ThrowingValidationSink: ValidationSink {
  public init() {
  }

  public func warning(_ message: String) {
    // No nothing.
  }

  public func recoverableError(_ message: String) throws(SARIFError) {
    // Treat as fatal error
    try fatalError(message)
  }

  public func fatalError(_ message: String) throws(SARIFError) -> Never {
    throw .invalidSARIF(message: message)
  }
}
