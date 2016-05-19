// RUN: %target-build-swift -sanitize=thread %s -o %t_binary
// RUN: TSAN_OPTIONS=ignore_interceptors_accesses=1 %t_binary
// REQUIRES: executable_test
// REQUIRES: objc_interop
// REQUIRES: CPU=x86_64
// REQUIRES: OS=macosx

// We expect not to report any races on this testcase.

// This test excercises accesses to type metadata, which uses lockless
// syncronization in the runtime that is relied upon by the direct accesses in the IR.
// We have to make sure TSan does not see the acesses to the metadata from the IR.
// Otherwise, it will report a race.

import Dispatch

// Generic classes.
private class KeyWrapper<T: Hashable>: NSObject {
  let value: T

  init(_ value: T) {
    self.value = value
  }
  override func isEqual(_ object: AnyObject?) -> Bool {
    return value == (object as! KeyWrapper<T>).value
  }
  override var hash: Int {
    return value.hashValue
  }
  func present() {
    print("Key: \(value)")
  }
}
private class ValueWrapper<T> {
  let value: T
  init(_ value: T) {
    self.value = value
  }
  func present() {
    print("Value: \(value)")
  }
}

// Concrete a class that inherits a generic base.
class Base<T> {
  var first, second: T
  required init(x: T) {
    first = x
    second = x
  }
  func present() {
    print("\(self.dynamicType) \(T.self) \(first) \(second)")
  }
}
class SuperDerived: Derived {
}
class Derived: Base<String> {
  var third: String
  required init(x: String) {
    third = x
    super.init(x: x)
  }
  override func present() {
    super.present()
    print("...and \(third)")
  }
}
func presentBase<T>(_ base: Base<T>) {
  base.present()
}
func presentDerived(_ derived: Derived) {
  derived.present()
}

public class TestConcurrent<Key: Hashable, Value> {
  // Race on this code!
  public func race(_ key: Key, _ value: Value) {
    let wrappedKey = KeyWrapper(key)
    wrappedKey.present()
    ValueWrapper(value).present()
    presentBase(SuperDerived(x: "two"))
    presentBase(Derived(x: "two"))
    presentBase(Base(x: "two"))
    presentBase(Base(x: 2))
    presentDerived(Derived(x: "two"))
  }
}

func testForRaces() {
  let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
  let squares = TestConcurrent<Int, Int>()
  // The number of concurrent iterations to dispatch.
  let iterations = 10
  let numItems = 4

  dispatch_apply(iterations, queue) { i in
    let n = i % numItems
    squares.race(n, n)
  }
}

testForRaces()
