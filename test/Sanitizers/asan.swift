// RUN: %target-swiftc_driver %s -g -sanitize=address -o %t_tsan-binary
// RUN: not --crash %target-run %t_tsan-binary 2>&1 | FileCheck %s
// REQUIRES: executable_test
// REQUIRES: objc_interop
// XFAIL: linux

// Test AddressSanitizer execution end-to-end.

//import Foundation
//let b = UnsafeMutablePointer<CGFloat>(allocatingCapacity: 3)
//b.initializeFrom([0.1, 0.2, 0.3])
//b[4] = 0.4
// CHxECK: AddressSanitizer: heap-buffer-overflow


var a = UnsafeMutablePointer<Int>(allocatingCapacity: 1)
a.initialize(with: 5)
a.deinitialize(count: 1)
a.deallocateCapacity(1)
print(a.pointee)
a.deinitialize(count: 1)
a.deallocateCapacity(1)

// CHECK: AddressSanitizer: heap-use-after-free
