import Foundation
import OrderedCollections
public import SARIFRecords

internal protocol JSONRepresentableWithContext<Record> {
  associatedtype Record: Codable
  associatedtype Context

  func toJSON(with context: Context) throws -> Record
}

internal protocol JSONRepresentable<Record>: JSONRepresentableWithContext
where Context == Void {
  func toJSON() throws -> Record
}

extension JSONRepresentable {
  func toJSON(with context: Context) throws -> Record {
    try toJSON()
  }
}

extension JSONRepresentable where Record == Self {
  func toJSON(with context: Context) -> Record { self }
  func toJSON() -> Record { self }
}

extension JSONRepresentableWithContext where Context == Void {
  func toJSON() throws -> Record {
    try toJSON(with: ())
  }
}

extension Array: JSONRepresentableWithContext
where Element: JSONRepresentableWithContext {
  func toJSON(with context: Element.Context) throws -> [Element.Record] {
    try self.map({ try $0.toJSON(with: context) })
  }

  var ifNotEmpty: Self? {
    if self.isEmpty {
      nil
    } else {
      self
    }
  }
}

extension Optional: JSONRepresentableWithContext
where Wrapped: JSONRepresentableWithContext {
  func toJSON(with context: Wrapped.Context) throws -> Wrapped.Record? {
    try self.map({ try $0.toJSON(with: context) })
  }
}

extension OrderedDictionary: JSONRepresentableWithContext
where Key: Codable, Value: JSONRepresentableWithContext {
  func toJSON(with context: Value.Context) throws -> JSONDictionary<
    Key, Value.Record
  > {
    var result = JSONDictionary<Key, Value.Record>()
    for (key, value) in self {
      result[key] = try value.toJSON(with: context)
    }

    return result
  }

  var ifNotEmpty: Self? {
    if self.isEmpty {
      nil
    } else {
      self
    }
  }
}

extension OrderedSet: JSONRepresentableWithContext
where Element: JSONRepresentableWithContext {
  func toJSON(with context: Element.Context) throws -> [Element.Record] {
    try self.elements.map({ try $0.toJSON(with: context) })
  }

  var ifNotEmpty: Self? {
    if self.isEmpty {
      nil
    } else {
      self
    }
  }
}

/*
extension JSONDictionary: JSONRepresentable<Self>, JSONRepresentableWithContext<Self> where V: Codable {
    typealias Context = Void

    var ifNotEmpty: Self? {
        if self.isEmpty {
            nil
        } else {
            self
        }
    }
}
*/

extension JSONDictionary: JSONRepresentableWithContext
where V: JSONRepresentableWithContext {
  func toJSON(with context: V.Context) throws -> JSONDictionary<K, V.Record> {
    try self.orderedDictionary.toJSON(with: context)
  }
}

extension AnyJSON: JSONRepresentable<AnyJSON> {
}

extension String: JSONRepresentable<String> {
}

extension UUID: JSONRepresentable<UUID> {
}

extension URL: JSONRepresentable<URL> {
}

extension Bool: JSONRepresentable<Bool> {
}

extension Float: JSONRepresentable<Float> {
}

extension Int32: JSONRepresentable<Int32> {
}

extension Int64: JSONRepresentable<Int64> {
}

extension HierarchicalString: JSONRepresentable<HierarchicalString> {

}
