// RUN: %target-run-simple-swift | FileCheck %s
// REQUIRES: executable_test

import SwiftPrivate
import StdlibUnittest

// Also import modules which are used by StdlibUnittest internally. This
// workaround is needed to link all required libraries in case we compile
// StdlibUnittest with -sil-serialize-all.
#if _runtime(_ObjC)
import ObjectiveC
#endif

_setOverrideOSVersion(.osx(major: 10, minor: 9, bugFix: 3))
_setTestSuiteFailedCallback() { print("abort()") }

//
// Test that harness aborts when a test fails
//

var TestSuitePasses = TestSuite("TestSuitePasses")
TestSuitePasses.test("passes") {
  expectEqual(1, 1)
}
// CHECK: [       OK ] TestSuitePasses.passes{{$}}
// CHECK: TestSuitePasses: All tests passed

var TestSuiteUXPasses = TestSuite("TestSuiteUXPasses")
TestSuiteUXPasses.test("uxpasses").xfail(.osxAny("")).code {
  expectEqual(1, 1)
}
// CHECK: [   UXPASS ] TestSuiteUXPasses.uxpasses{{$}}
// CHECK: TestSuiteUXPasses: Some tests failed, aborting
// CHECK: UXPASS: ["uxpasses"]
// CHECK: FAIL: []
// CHECK: SKIP: []
// CHECK: abort()

var TestSuiteFails = TestSuite("TestSuiteFails")
TestSuiteFails.test("fails") {
  expectEqual(1, 2)
}
// CHECK: [     FAIL ] TestSuiteFails.fails{{$}}
// CHECK: TestSuiteFails: Some tests failed, aborting
// CHECK: UXPASS: []
// CHECK: FAIL: ["fails"]
// CHECK: SKIP: []
// CHECK: abort()

var TestSuiteXFails = TestSuite("TestSuiteXFails")
TestSuiteXFails.test("xfails").xfail(.osxAny("")).code {
  expectEqual(1, 2)
}
// CHECK: [    XFAIL ] TestSuiteXFails.xfails{{$}}
// CHECK: TestSuiteXFails: All tests passed

//
// Test 'xfail:' and 'skip:' annotations
//

var XFailsAndSkips = TestSuite("XFailsAndSkips")

// CHECK: [       OK ] XFailsAndSkips.passes{{$}}
XFailsAndSkips.test("passes") {
  expectEqual(1, 1)
}

// CHECK: [     FAIL ] XFailsAndSkips.fails{{$}}
XFailsAndSkips.test("fails") {
  expectEqual(1, 2)
}

// CHECK: [    XFAIL ] XFailsAndSkips.fails-always{{$}}
XFailsAndSkips.test("fails-always")
  .xfail(.always("must always fail")).code {
  expectEqual(1, 2)
}

// CHECK: [      OK ] XFailsAndSkips.fails-never{{$}}
XFailsAndSkips.test("fails-never")
  .xfail(.never).code {
  expectEqual(1, 1)
}

// CHECK: [    XFAIL ] XFailsAndSkips.xfail 10.9.3 passes{{$}}
XFailsAndSkips.test("xfail 10.9.3 passes")
  .xfail(.osxBugFix(10, 9, 3, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [    XFAIL ] XFailsAndSkips.xfail 10.9.3 fails{{$}}
XFailsAndSkips.test("xfail 10.9.3 fails")
  .xfail(.osxBugFix(10, 9, 3, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [     SKIP ] XFailsAndSkips.skipAlways (skip: [Always(reason: skip)]){{$}}
XFailsAndSkips.test("skipAlways")
  .skip(.always("skip")).code {
    fatalError("should not happen")
}

// CHECK: [       OK ] XFailsAndSkips.skipNever{{$}}
XFailsAndSkips.test("skipNever")
  .skip(.never).code {
    expectEqual(1, 1)
}

// CHECK: [     FAIL ] XFailsAndSkips.skip 10.9.2 passes{{$}}
XFailsAndSkips.test("skip 10.9.2 passes")
  .skip(.osxBugFix(10, 9, 2, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [     FAIL ] XFailsAndSkips.skip 10.9.2 fails{{$}}
XFailsAndSkips.test("skip 10.9.2 fails")
  .skip(.osxBugFix(10, 9, 2, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [ SKIP     ] XFailsAndSkips.skip 10.9.3 (skip: [osx(10.9.3, reason: )]){{$}}
XFailsAndSkips.test("skip 10.9.3")
  .skip(.osxBugFix(10, 9, 3, reason: "")).code {
  expectEqual(1, 2)
  fatalError("should not be executed")
}

// CHECK: XFailsAndSkips: Some tests failed, aborting
// CHECK: abort()

//
// Test custom XFAIL predicates
//

var XFailsCustomPredicates = TestSuite("XFailsCustomPredicates")

// CHECK: [    XFAIL ] XFailsCustomPredicates.matches{{$}}
XFailsCustomPredicates.test("matches")
  .xfail(.custom({ true }, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [       OK ] XFailsCustomPredicates.not matches{{$}}
XFailsCustomPredicates.test("not matches")
  .xfail(.custom({ false }, reason: "")).code {
  expectEqual(1, 1)
}

// CHECK: XFailsCustomPredicates: All tests passed

//
// Test version comparison rules
//

var XFailsOSX = TestSuite("XFailsOSX")

// CHECK: [   UXPASS ] XFailsOSX.xfail OSX passes{{$}}
XFailsOSX.test("xfail OSX passes").xfail(.osxAny("")).code {
  expectEqual(1, 1)
}

// CHECK: [    XFAIL ] XFailsOSX.xfail OSX fails{{$}}
XFailsOSX.test("xfail OSX fails").xfail(.osxAny("")).code {
  expectEqual(1, 2)
}

// CHECK: [       OK ] XFailsOSX.xfail 9.*{{$}}
XFailsOSX.test("xfail 9.*").xfail(.osxMajor(9, reason: "")).code {
  expectEqual(1, 1)
}

// CHECK: [    XFAIL ] XFailsOSX.xfail 10.*{{$}}
XFailsOSX.test("xfail 10.*").xfail(.osxMajor(10, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [       OK ] XFailsOSX.xfail 10.8{{$}}
XFailsOSX.test("xfail 10.8").xfail(.osxMinor(10, 8, reason: "")).code {
  expectEqual(1, 1)
}

// CHECK: [    XFAIL ] XFailsOSX.xfail 10.9{{$}}
XFailsOSX.test("xfail 10.9").xfail(.osxMinor(10, 9, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [       OK ] XFailsOSX.xfail 10.[7-8]{{$}}
XFailsOSX.test("xfail 10.[7-8]")
  .xfail(.osxMinorRange(10, 7...8, reason: "")).code {
  expectEqual(1, 1)
}

// CHECK: [    XFAIL ] XFailsOSX.xfail 10.[9-10]{{$}}
XFailsOSX.test("xfail 10.[9-10]")
  .xfail(.osxMinorRange(10, 9...10, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [       OK ] XFailsOSX.xfail 10.9.2{{$}}
XFailsOSX.test("xfail 10.9.2")
  .xfail(.osxBugFix(10, 9, 2, reason: "")).code {
  expectEqual(1, 1)
}

// CHECK: [    XFAIL ] XFailsOSX.xfail 10.9.3{{$}}
XFailsOSX.test("xfail 10.9.3")
  .xfail(.osxBugFix(10, 9, 3, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: [       OK ] XFailsOSX.xfail 10.9.[1-2]{{$}}
XFailsOSX.test("xfail 10.9.[1-2]")
  .xfail(.osxBugFixRange(10, 9, 1...2, reason: "")).code {
  expectEqual(1, 1)
}

// CHECK: [    XFAIL ] XFailsOSX.xfail 10.9.[3-4]{{$}}
XFailsOSX.test("xfail 10.9.[3-4]")
  .xfail(.osxBugFixRange(10, 9, 3...4, reason: "")).code {
  expectEqual(1, 2)
}

// CHECK: XFailsOSX: Some tests failed, aborting
// CHECK: abort()

//
// Check that we pass through stdout and stderr
//

var PassThroughStdoutStderr = TestSuite("PassThroughStdoutStderr")

PassThroughStdoutStderr.test("hasNewline") {
  print("stdout first")
  print("stdout second")
  print("stdout third")

  var stderr = _Stderr()
  print("stderr first", to: &stderr)
  print("stderr second", to: &stderr)
  print("stderr third", to: &stderr)
}
// CHECK: [ RUN      ] PassThroughStdoutStderr.hasNewline
// CHECK-DAG: stdout>>> stdout first
// CHECK-DAG: stdout>>> stdout second
// CHECK-DAG: stdout>>> stdout third
// CHECK-DAG: stderr>>> stderr first
// CHECK-DAG: stderr>>> stderr second
// CHECK-DAG: stderr>>> stderr third
// CHECK: [       OK ] PassThroughStdoutStderr.hasNewline

PassThroughStdoutStderr.test("noNewline") {
  print("stdout first")
  print("stdout second")
  print("stdout third", terminator: "")

  var stderr = _Stderr()
  print("stderr first", to: &stderr)
  print("stderr second", to: &stderr)
  print("stderr third", terminator: "", to: &stderr)
}
// CHECK: [ RUN      ] PassThroughStdoutStderr.noNewline
// CHECK-DAG: stdout>>> stdout first
// CHECK-DAG: stdout>>> stdout second
// CHECK-DAG: stdout>>> stdout third
// CHECK-DAG: stderr>>> stderr first
// CHECK-DAG: stderr>>> stderr second
// CHECK-DAG: stderr>>> stderr third
// CHECK: [       OK ] PassThroughStdoutStderr.noNewline
// CHECK: PassThroughStdoutStderr: All tests passed

//
// Test 'setUp' and 'tearDown'
//

var TestSuiteWithSetUpPasses = TestSuite("TestSuiteWithSetUpPasses")

TestSuiteWithSetUpPasses.test("passes") {
  print("test body")
}

TestSuiteWithSetUpPasses.setUp {
  print("setUp")
}
// CHECK: [ RUN      ] TestSuiteWithSetUpPasses.passes
// CHECK: stdout>>> setUp
// CHECK: stdout>>> test body
// CHECK: [       OK ] TestSuiteWithSetUpPasses.passes
// CHECK: TestSuiteWithSetUpPasses: All tests passed

var TestSuiteWithSetUpFails = TestSuite("TestSuiteWithSetUpFails")

TestSuiteWithSetUpFails.test("fails") {
  print("test body")
}

TestSuiteWithSetUpFails.setUp {
  print("setUp")
  expectEqual(1, 2)
}
// CHECK: [ RUN      ] TestSuiteWithSetUpFails.fails
// CHECK: stdout>>> setUp
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> test body
// CHECK: [     FAIL ] TestSuiteWithSetUpFails.fails
// CHECK: TestSuiteWithSetUpFails: Some tests failed, aborting

var TestSuiteWithTearDownPasses = TestSuite("TestSuiteWithTearDownPasses")

TestSuiteWithTearDownPasses.test("passes") {
  print("test body")
}

TestSuiteWithTearDownPasses.tearDown {
  print("tearDown")
}
// CHECK: [ RUN      ] TestSuiteWithTearDownPasses.passes
// CHECK: stdout>>> test body
// CHECK: stdout>>> tearDown
// CHECK: [       OK ] TestSuiteWithTearDownPasses.passes

var TestSuiteWithTearDownFails = TestSuite("TestSuiteWithTearDownFails")

TestSuiteWithTearDownFails.test("fails") {
  print("test body")
}

TestSuiteWithTearDownFails.tearDown {
  print("tearDown")
  expectEqual(1, 2)
}
// CHECK: TestSuiteWithTearDownPasses: All tests passed
// CHECK: [ RUN      ] TestSuiteWithTearDownFails.fails
// CHECK: stdout>>> test body
// CHECK: stdout>>> tearDown
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: [     FAIL ] TestSuiteWithTearDownFails.fails
// CHECK: TestSuiteWithTearDownFails: Some tests failed, aborting

//
// Test assertions
//

var AssertionsTestSuite = TestSuite("Assertions")

AssertionsTestSuite.test("expectFailure/Pass") {
  expectFailure {
    expectEqual(1, 2)
    return ()
  }
}
// CHECK: [ RUN      ] Assertions.expectFailure/Pass
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: 1 (of type Swift.Int)
// CHECK: stdout>>> actual: 2 (of type Swift.Int)
// CHECK: [       OK ] Assertions.expectFailure/Pass

AssertionsTestSuite.test("expectFailure/UXPass")
  .xfail(.custom({ true }, reason: "test"))
  .code {
  expectFailure {
    expectEqual(1, 2)
    return ()
  }
}
// CHECK: [ RUN      ] Assertions.expectFailure/UXPass ({{X}}FAIL: [Custom(reason: test)])
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: 1 (of type Swift.Int)
// CHECK: stdout>>> actual: 2 (of type Swift.Int)
// CHECK: [   UXPASS ] Assertions.expectFailure/UXPass

AssertionsTestSuite.test("expectFailure/Fail") {
  expectFailure {
    return ()
  }
}
// CHECK: [ RUN      ] Assertions.expectFailure/Fail
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: true
// CHECK: stdout>>> running `body` should produce an expected failure
// CHECK: [     FAIL ] Assertions.expectFailure/Fail

AssertionsTestSuite.test("expectFailure/XFail")
  .xfail(.custom({ true }, reason: "test"))
  .code {
  expectFailure {
    return ()
  }
}
// CHECK: [ RUN      ] Assertions.expectFailure/XFail ({{X}}FAIL: [Custom(reason: test)])
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: true
// CHECK: stdout>>> running `body` should produce an expected failure
// CHECK: [    XFAIL ] Assertions.expectFailure/XFail

AssertionsTestSuite.test("expectFailure/AfterFailure/Fail") {
  expectEqual(1, 2)
  expectFailure {
    expectEqual(3, 4)
    return ()
  }
}
// CHECK: [ RUN      ] Assertions.expectFailure/AfterFailure/Fail
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: 1 (of type Swift.Int)
// CHECK: stdout>>> actual: 2 (of type Swift.Int)
// CHECK: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: 3 (of type Swift.Int)
// CHECK: stdout>>> actual: 4 (of type Swift.Int)
// CHECK: [     FAIL ] Assertions.expectFailure/AfterFailure/Fail

AssertionsTestSuite.test("expectFailure/AfterFailure/XFail")
  .xfail(.custom({ true }, reason: "test"))
  .code {
  expectEqual(1, 2)
  expectFailure {
    expectEqual(3, 4)
    return ()
  }
}
// CHECK: [ RUN      ] Assertions.expectFailure/AfterFailure/XFail ({{X}}FAIL: [Custom(reason: test)])
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: 1 (of type Swift.Int)
// CHECK: stdout>>> actual: 2 (of type Swift.Int)
// CHECK: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> expected: 3 (of type Swift.Int)
// CHECK: stdout>>> actual: 4 (of type Swift.Int)
// CHECK: [    XFAIL ] Assertions.expectFailure/AfterFailure/XFail

AssertionsTestSuite.test("expectUnreachable") {
  expectUnreachable()
}
// CHECK: [ RUN      ] Assertions.expectUnreachable
// CHECK-NEXT: stdout>>> check failed at {{.*}}/StdlibUnittest/Common.swift, line
// CHECK: stdout>>> this code should not be executed
// CHECK: [     FAIL ] Assertions.expectUnreachable

AssertionsTestSuite.test("expectCrashLater/Pass") {
  let array: [Int] = _opaqueIdentity([])
  expectCrashLater()
  _blackHole(array[0])
}
// CHECK: [ RUN      ] Assertions.expectCrashLater/Pass
// CHECK: stderr>>> OK: saw expected "crashed: sig{{.*}}
// CHECK: [       OK ] Assertions.expectCrashLater/Pass

AssertionsTestSuite.test("expectCrashLater/UXPass")
  .xfail(.custom({ true }, reason: "test"))
  .code {
  let array: [Int] = _opaqueIdentity([])
  expectCrashLater()
  _blackHole(array[0])
}
// CHECK: [ RUN      ] Assertions.expectCrashLater/UXPass ({{X}}FAIL: [Custom(reason: test)])
// CHECK: stderr>>> OK: saw expected "crashed: sig{{.*}}
// CHECK: [   UXPASS ] Assertions.expectCrashLater/UXPass

AssertionsTestSuite.test("expectCrashLater/Fail") {
  expectCrashLater()
}
// CHECK: [ RUN      ] Assertions.expectCrashLater/Fail
// CHECK: expecting a crash, but the test did not crash
// CHECK: [     FAIL ] Assertions.expectCrashLater/Fail

AssertionsTestSuite.test("expectCrashLater/XFail")
  .xfail(.custom({ true }, reason: "test"))
  .code {
  expectCrashLater()
}
// CHECK: [ RUN      ] Assertions.expectCrashLater/XFail ({{X}}FAIL: [Custom(reason: test)])
// CHECK: expecting a crash, but the test did not crash
// CHECK: [    XFAIL ] Assertions.expectCrashLater/XFail

AssertionsTestSuite.test("UnexpectedCrash/RuntimeTrap") {
  let array: [Int] = _opaqueIdentity([])
  _blackHole(array[0])
}
// CHECK: [ RUN      ] Assertions.UnexpectedCrash/RuntimeTrap
// CHECK: stderr>>> CRASHED: SIG
// CHECK: the test crashed unexpectedly
// CHECK: [     FAIL ] Assertions.UnexpectedCrash/RuntimeTrap

AssertionsTestSuite.test("UnexpectedCrash/NullPointerDereference") {
  let ptr: UnsafePointer<Int> = _opaqueIdentity(nil)
  _blackHole(ptr.pointee)
}
// CHECK: [ RUN      ] Assertions.UnexpectedCrash/NullPointerDereference
// CHECK: stderr>>> CRASHED: SIG
// CHECK: the test crashed unexpectedly
// CHECK: [     FAIL ] Assertions.UnexpectedCrash/NullPointerDereference

var TestSuiteLifetimeTracked = TestSuite("TestSuiteLifetimeTracked")
var leakMe: LifetimeTracked? = nil
TestSuiteLifetimeTracked.test("failsIfLifetimeTrackedAreLeaked") {
  leakMe = LifetimeTracked(0)
}
// CHECK: [ RUN      ] TestSuiteLifetimeTracked.failsIfLifetimeTrackedAreLeaked
// CHECK-NEXT: stdout>>> check failed at {{.*}}.swift, line [[@LINE-4]]
// CHECK: stdout>>> expected: 0 (of type Swift.Int)
// CHECK: stdout>>> actual: 1 (of type Swift.Int)
// CHECK: [     FAIL ] TestSuiteLifetimeTracked.failsIfLifetimeTrackedAreLeaked

TestSuiteLifetimeTracked.test("passesIfLifetimeTrackedAreResetAfterFailure") {}
// CHECK: [ RUN      ] TestSuiteLifetimeTracked.passesIfLifetimeTrackedAreResetAfterFailure
// CHECK: [       OK ] TestSuiteLifetimeTracked.passesIfLifetimeTrackedAreResetAfterFailure

runAllTests()

