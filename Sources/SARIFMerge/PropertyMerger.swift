internal import OrderedCollections
internal import SARIF

struct PropertyMerger<T> {
  let input: T
  var output: T
  let first: Bool
  let sink: any ValidationSink

  init(from input: T, into output: T, first: Bool, sink: any ValidationSink) {
    self.input = input
    self.output = output
    self.first = first
    self.sink = sink
  }

  mutating func concatenate<E>(key: WritableKeyPath<T, [E]>) throws {
    let inputValue = self.input[keyPath: key]
    self.output[keyPath: key].append(contentsOf: inputValue)
  }

  mutating func mergeFirst<V: MergeableValue>(
    key: WritableKeyPath<T, V?>, with context: V.Context, make: () -> V
  ) throws {
    if self.first {
      let inputValue = self.input[keyPath: key]
      if let inputValue {
        var mergeState = V.MergeState()
        var valueMerger = PropertyMerger<V>(
          from: inputValue, into: make(), first: true, sink: self.sink)
        try mergeState.merge(merger: &valueMerger, with: context)
        self.output[keyPath: key] = valueMerger.output
      } else {
        self.output[keyPath: key] = nil
      }
    }
  }

  mutating func mergeFirst<V: MergeableValue>(
    key: WritableKeyPath<T, [V]>, with context: V.Context, make: () -> V
  ) throws {
    if self.first {
      let inputValues = self.input[keyPath: key]
      var outputValues: [V] = []
      outputValues.reserveCapacity(inputValues.count)

      for inputValue in inputValues {
        var mergeState = V.MergeState()
        var valueMerger = PropertyMerger<V>(
          from: inputValue, into: make(), first: true, sink: self.sink)
        try mergeState.merge(merger: &valueMerger, with: context)
        outputValues.append(valueMerger.output)
      }

      self.output[keyPath: key] = outputValues
    }
  }

  mutating func keepFirstReference<V: AnyObject>(
    key: WritableKeyPath<T, V>, resolve: (V) throws -> V
  ) throws {
    if self.first {
      let inputReference = self.input[keyPath: key]
      let outputReference = try resolve(inputReference)
      self.output[keyPath: key] = outputReference
    }
  }

  func keepFirst<each V>(keys: repeat ReferenceWritableKeyPath<T, each V>)
    throws
  {
    if self.first {
      for key in repeat each keys {
        self.output[keyPath: key] = self.input[keyPath: key]
      }
    }
  }

  func keepFirstSpecified<each V>(
    keys: repeat ReferenceWritableKeyPath<T, (each V)?>
  ) throws {
    for key in repeat each keys {
      if self.output[keyPath: key] == nil {
        if let inputValue = self.input[keyPath: key] {
          self.output[keyPath: key] = inputValue
        }
      }
    }
  }

  func assertIdentical<V: AnyObject>(
    key: ReferenceWritableKeyPath<T, V>, definitions: ReferenceMergeMap<V>
  ) throws {
    let originalInputValue = self.input[keyPath: key]
    let resolvedInputValue = definitions.resolve(from: originalInputValue)
    if self.first {
      self.output[keyPath: key] = resolvedInputValue
    } else {
      let outputValue = self.output[keyPath: key]
      guard resolvedInputValue === outputValue else {
        try sink.fatalError(
          "Unexpected unequal values for property '\(key.debugDescription)'.")
      }
    }
  }

  func assertEqual<each V: Equatable>(
    keys: repeat ReferenceWritableKeyPath<T, each V>
  ) throws {
    for key in repeat each keys {
      let inputValue = self.input[keyPath: key]
      if self.first {
        self.output[keyPath: key] = inputValue
      } else {
        let outputValue = self.output[keyPath: key]
        guard inputValue == outputValue else {
          try sink.fatalError(
            "Unexpected unequal values for property '\(key.debugDescription)'.")
        }
      }
    }
  }

  func assertEqualOrNil<each V: Equatable>(
    keys: repeat ReferenceWritableKeyPath<T, (each V)?>
  )
    throws
  {
    for key in repeat each keys {
      if let inputValue = self.input[keyPath: key] {
        if let outputValue = self.output[keyPath: key] {
          guard inputValue == outputValue else {
            try sink.fatalError(
              "Unexpected unequal values for property '\(key.debugDescription)'."
            )
          }
        } else {
          self.output[keyPath: key] = inputValue
        }
      }
    }
  }

  mutating func expectEqual<each V: Equatable>(
    keys: repeat WritableKeyPath<T, each V>
  ) throws {
    for key in repeat each keys {
      let inputValue = self.input[keyPath: key]
      if self.first {
        self.output[keyPath: key] = inputValue
      } else {
        let outputValue = self.output[keyPath: key]
        if inputValue != outputValue {
          try sink.recoverableError(
            "Expected values for property '\(key.debugDescription)' to be equal. Using the first value specified."
          )
        }
      }
    }
  }

  func assertNil<each V>(keys: repeat KeyPath<T, (each V)?>) throws {
    for key in repeat each keys {
      guard self.input[keyPath: key] == nil else {
        try self.sink.fatalError(
          "Unexpected non-nil value for property '\(key.debugDescription)'.")
      }
    }
  }

  func union<each V: Hashable>(
    keys: repeat ReferenceWritableKeyPath<T, OrderedSet<each V>>
  ) throws {
    for key in repeat each keys {
      self.output[keyPath: key].formUnion(self.input[keyPath: key])
    }
  }

  func ignore<each V>(keys: repeat KeyPath<T, each V>) throws {
    // No effect
  }
}
