// RUN: %target-build-swift -sanitize=thread %s -o %t_binary
// RUN: TSAN_OPTIONS=ignore_interceptors_accesses=1 %t_binary
// REQUIRES: executable_test
// REQUIRES: objc_interop
// REQUIRES: CPU=x86_64
// REQUIRES: OS=macosx

// Check taht TSan does not report spurious races in witness table lookup.

import Dispatch

func consume(_ x: Any) {}
protocol Q {
  associatedtype QA
  func deduceQA() -> QA
  static func foo()
}
extension Q {
  func deduceQA() -> Int { return 0 }
}
protocol Q2 {
  associatedtype Q2A
  func deduceQ2A() -> Q2A
}
extension Q2 {
  func deduceQ2A() -> Int { return 0 }
}
protocol P {
  associatedtype E : Q, Q2
}
struct B<T : Q> : Q, Q2 {
  static func foo() { consume(self.dynamicType) }
}
struct A<T : Q where T : Q2> : P {
  typealias E = B<T>
  let value: T
}
func foo<T : P>(_ t: T) {
  T.E.foo()
}
struct EasyType : Q, Q2 {
    static func foo() { consume(self.dynamicType) }
}
extension Int : Q, Q2 {
  static func foo() { consume(self.dynamicType) }
}

// Race on this code!
func race(_ i: Int) {
  foo(A<Int>(value: i))
  foo(A<Int>(value: Int()))
  foo(A<EasyType>(value: EasyType()))
}

func testForRaces() {
  let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
  // The number of concurrent iterations to dispatch.
  let iterations = 10000
  dispatch_apply(iterations, queue) { i in
    race(i)
  }
}

testForRaces()
