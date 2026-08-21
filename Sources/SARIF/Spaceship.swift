infix operator <=>

internal protocol SpaceshipComparable {
  static func <=> (_ lhs: Self, _ rhs: Self) -> Bool?
}

extension Comparable {
  static func <=> (_ lhs: Self, _ rhs: Self) -> Bool? {
    if lhs == rhs {
      return nil
    } else {
      return lhs < rhs
    }
  }
}

extension Optional {
  static func <=> (_ lhs: Self, _ rhs: Self) -> Bool?
  where Wrapped: SpaceshipComparable {
    switch (lhs, rhs) {
    case (nil, nil): nil
    case (nil, .some): false
    case (.some, nil): true
    case (.some(let lhs), .some(let rhs)): lhs <=> rhs
    }
  }

  @_disfavoredOverload
  static func <=> (_ lhs: Self, _ rhs: Self) -> Bool?
  where Wrapped: Comparable {
    switch (lhs, rhs) {
    case (nil, nil): nil
    case (nil, .some): false
    case (.some, nil): true
    case (.some(let lhs), .some(let rhs)): lhs <=> rhs
    }
  }
}
