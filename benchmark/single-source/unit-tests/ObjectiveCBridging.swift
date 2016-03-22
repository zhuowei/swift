//===--- ObjectiveCBridging.swift -----------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import TestsUtils
import Foundation

@inline(never)
public func forcedCast<NS, T>(ns: NS) -> T {
  return ns as! T
}

@inline(never)
public func conditionalCast<NS, T>(ns: NS) -> T? {
  return ns as? T
}


// === String === //

func createNSString() -> NSString {
	return NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
}

@inline(never)
func testObjectiveCBridgeFromNSString() {
  let nsString = createNSString()

  var s: String?
  for _ in 0 ..< 10_000 {
    // Call _conditionallyBridgeFromObjectiveC.
    let n : String? = conditionalCast(nsString)
    if n != nil {
      s = n!
    }
  }
  CheckResults(s != nil && s == "NSString that does not fit in tagged pointer", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSString(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSString()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSStringForced() {
  let nsString = createNSString()

  var s: String?
  for _ in 0 ..< 10_000 {
    // Call _forceBridgeFromObjectiveC
    s = forcedCast(nsString)
  }
  CheckResults(s != nil && s == "NSString that does not fit in tagged pointer", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSStringForced(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSStringForced()
  }
}

@inline(never)
func testObjectiveCBridgeToNSString() {
  let nativeString = String("Native")

  var s: NSString?
  for _ in 0 ..< 10_000 {
    // Call _BridgedToObjectiveC
    s = nativeString as NSString
  }
  CheckResults(s != nil && s == "Native", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeToNSString(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeToNSString()
  }
}

// === Array === //

func createNSArray() -> NSArray {
  let nsMutableArray = NSMutableArray()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  nsMutableArray.add(nsString)
  return nsMutableArray.copy() as! NSArray
}

@inline(never)
func testObjectiveCBridgeFromNSArrayAnyObject() {
  let nsArray = createNSArray()

  var nativeString : String?
  for _ in 0 ..< 10_000 {
    if let nativeArray : [NSString] = conditionalCast(nsArray) {
       nativeString = forcedCast(nativeArray[0])
    }
  }
  CheckResults(nativeString != nil && nativeString! == "NSString that does not fit in tagged pointer", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSArrayAnyObject(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSArrayAnyObject()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSArrayAnyObjectForced() {
  let nsArray = createNSArray()

  var nativeString : String?
  for _ in 0 ..< 10_000 {
    let nativeArray : [NSString] = forcedCast(nsArray)
    nativeString = forcedCast(nativeArray[0])
  }
  CheckResults(nativeString != nil && nativeString! == "NSString that does not fit in tagged pointer", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSArrayAnyObjectForced(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSArrayAnyObjectForced()
  }
}

@inline(never)
func testObjectiveCBridgeToNSArray() {
  let nativeArray = [ "abcde", "abcde", "abcde", "abcde", "abcde",
                      "abcde", "abcde", "abcde", "abcde", "abcde"]

  var nsString : AnyObject?
  for _ in 0 ..< 10_000 {
    let nsArray = nativeArray as NSArray
    nsString = nsArray.object(at: 0)
  }
  CheckResults(nsString != nil && (nsString! as! NSString).isEqual("abcde"), "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeToNSArray(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeToNSArray()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSArrayAnyObjectToString() {
  let nsArray = createNSArray()

  var nativeString : String?
  for _ in 0 ..< 10_000 {
    if let nativeArray : [String] = conditionalCast(nsArray) {
       nativeString = nativeArray[0]
    }
  }
	CheckResults(nativeString != nil && nativeString == "NSString that does not fit in tagged pointer", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSArrayAnyObjectToString(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSArrayAnyObjectToString()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSArrayAnyObjectToStringForced() {
  let nsArray = createNSArray()

  var nativeString : String?
  for _ in 0 ..< 10_000 {
    let nativeArray : [String] = forcedCast(nsArray)
    nativeString = nativeArray[0]
  }
	CheckResults(nativeString != nil && nativeString == "NSString that does not fit in tagged pointer", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSArrayAnyObjectToStringForced(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSArrayAnyObjectToStringForced()
  }
}

// === Dictionary === //

func createNSDictionary() -> NSDictionary {
  let nsMutableDictionary = NSMutableDictionary()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
  let nsString2 = NSString(cString: "NSString that does not fit in tagged pointer 2", encoding: NSUTF8StringEncoding)!
  let nsString3 = NSString(cString: "NSString that does not fit in tagged pointer 3", encoding: NSUTF8StringEncoding)!
  let nsString4 = NSString(cString: "NSString that does not fit in tagged pointer 4", encoding: NSUTF8StringEncoding)!
  let nsString5 = NSString(cString: "NSString that does not fit in tagged pointer 5", encoding: NSUTF8StringEncoding)!
  let nsString6 = NSString(cString: "NSString that does not fit in tagged pointer 6", encoding: NSUTF8StringEncoding)!
  let nsString7 = NSString(cString: "NSString that does not fit in tagged pointer 7", encoding: NSUTF8StringEncoding)!
  let nsString8 = NSString(cString: "NSString that does not fit in tagged pointer 8", encoding: NSUTF8StringEncoding)!
  let nsString9 = NSString(cString: "NSString that does not fit in tagged pointer 9", encoding: NSUTF8StringEncoding)!
  let nsString10 = NSString(cString: "NSString that does not fit in tagged pointer 10", encoding: NSUTF8StringEncoding)!
  nsMutableDictionary.setObject(1, forKey: nsString)
  nsMutableDictionary.setObject(2, forKey: nsString2)
  nsMutableDictionary.setObject(3, forKey: nsString3)
  nsMutableDictionary.setObject(4, forKey: nsString4)
  nsMutableDictionary.setObject(5, forKey: nsString5)
  nsMutableDictionary.setObject(6, forKey: nsString6)
  nsMutableDictionary.setObject(7, forKey: nsString7)
  nsMutableDictionary.setObject(8, forKey: nsString8)
  nsMutableDictionary.setObject(9, forKey: nsString9)
  nsMutableDictionary.setObject(10, forKey: nsString10)

  return nsMutableDictionary.copy() as! NSDictionary
}

@inline(never)
func testObjectiveCBridgeFromNSDictionaryAnyObject() {
  let nsDictionary = createNSDictionary()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!

  var nativeInt : Int?
  for _ in 0 ..< 10_000 {
    if let nativeDictionary : [NSString : NSNumber] = conditionalCast(nsDictionary) {
       nativeInt = forcedCast(nativeDictionary[nsString])
    }
  }
	CheckResults(nativeInt != nil && nativeInt == 1, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSDictionaryAnyObject(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSDictionaryAnyObject()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSDictionaryAnyObjectForced() {
  let nsDictionary = createNSDictionary()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!

  var nativeInt : Int?
  for _ in 0 ..< 10_000 {
    if let nativeDictionary : [NSString : NSNumber] = forcedCast(nsDictionary) {
       nativeInt = forcedCast(nativeDictionary[nsString])
    }
  }
	CheckResults(nativeInt != nil && nativeInt == 1, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSDictionaryAnyObjectForced(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSDictionaryAnyObjectForced()
  }
}

@inline(never)
func testObjectiveCBridgeToNSDictionary() {
  let nativeDictionary = [ "abcde1" : 1, "abcde2" : 2, "abcde3" : 3, "abcde4" : 4, "abcde5" : 5,
                      "abcde6" : 6, "abcde7" : 7, "abcde8" : 8, "abcde9" : 9, "abcde10" : 10]
  let key = "abcde1" as NSString

  var nsNumber : AnyObject?
  for _ in 0 ..< 10_000 {
    let nsDict = nativeDictionary as NSDictionary
    nsNumber = nsDict.object(forKey: key)
  }
	CheckResults(nsNumber != nil && (nsNumber as! Int) == 1, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeToNSDictionary(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeToNSDictionary()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSDictionaryAnyObjectToString() {
  let nsDictionary = createNSDictionary()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
	let nativeString = nsString as String

  var nativeInt : Int?
  for _ in 0 ..< 10_000 {
    if let nativeDictionary : [String : Int] = conditionalCast(nsDictionary) {
       nativeInt = nativeDictionary[nativeString]
    }
  }
	CheckResults(nativeInt != nil && nativeInt == 1, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSDictionaryAnyObjectToString(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSDictionaryAnyObjectToString()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSDictionaryAnyObjectToStringForced() {
  let nsDictionary = createNSDictionary()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
	let nativeString = nsString as String

  var nativeInt : Int?
  for _ in 0 ..< 10_000 {
    if let nativeDictionary : [String : Int] = forcedCast(nsDictionary) {
       nativeInt = nativeDictionary[nativeString]
    }
  }
	CheckResults(nativeInt != nil && nativeInt == 1, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSDictionaryAnyObjectToStringForced(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSDictionaryAnyObjectToStringForced()
  }
}

// === Set === //

func createNSSet() -> NSSet {
  let nsMutableSet = NSMutableSet()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
  let nsString2 = NSString(cString: "NSString that does not fit in tagged pointer 2", encoding: NSUTF8StringEncoding)!
  let nsString3 = NSString(cString: "NSString that does not fit in tagged pointer 3", encoding: NSUTF8StringEncoding)!
  let nsString4 = NSString(cString: "NSString that does not fit in tagged pointer 4", encoding: NSUTF8StringEncoding)!
  let nsString5 = NSString(cString: "NSString that does not fit in tagged pointer 5", encoding: NSUTF8StringEncoding)!
  let nsString6 = NSString(cString: "NSString that does not fit in tagged pointer 6", encoding: NSUTF8StringEncoding)!
  let nsString7 = NSString(cString: "NSString that does not fit in tagged pointer 7", encoding: NSUTF8StringEncoding)!
  let nsString8 = NSString(cString: "NSString that does not fit in tagged pointer 8", encoding: NSUTF8StringEncoding)!
  let nsString9 = NSString(cString: "NSString that does not fit in tagged pointer 9", encoding: NSUTF8StringEncoding)!
  let nsString10 = NSString(cString: "NSString that does not fit in tagged pointer 10", encoding: NSUTF8StringEncoding)!
  nsMutableSet.add(nsString)
  nsMutableSet.add(nsString2)
  nsMutableSet.add(nsString3)
  nsMutableSet.add(nsString4)
  nsMutableSet.add(nsString5)
  nsMutableSet.add(nsString6)
  nsMutableSet.add(nsString7)
  nsMutableSet.add(nsString8)
  nsMutableSet.add(nsString9)
  nsMutableSet.add(nsString10)

  return nsMutableSet.copy() as! NSSet
}


@inline(never)
func testObjectiveCBridgeFromNSSetAnyObject() {
  let nsSet = createNSSet()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!

  var result : Bool?
  for _ in 0 ..< 10_000 {
    if let nativeSet : Set<NSString> = conditionalCast(nsSet) {
       result = nativeSet.contains(nsString)
    }
  }
	CheckResults(result != nil && result!, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSSetAnyObject(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSSetAnyObject()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSSetAnyObjectForced() {
  let nsSet = createNSSet()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!

  var result : Bool?
  for _ in 0 ..< 10_000 {
    if let nativeSet : Set<NSString> = forcedCast(nsSet) {
       result = nativeSet.contains(nsString)
    }
  }
	CheckResults(result != nil && result!, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSSetAnyObjectForced(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSSetAnyObjectForced()
  }
}

@inline(never)
func testObjectiveCBridgeToNSSet() {
  let nativeSet = Set<String>([ "abcde1", "abcde2", "abcde3", "abcde4", "abcde5",
                      "abcde6", "abcde7", "abcde8", "abcde9", "abcde10"])
  let key = "abcde1" as NSString

  var nsString : AnyObject?
  for _ in 0 ..< 10_000 {
    let nsDict = nativeSet as NSSet
    nsString = nsDict.member(key)
  }
	CheckResults(nsString != nil && (nsString as! String) == "abcde1", "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeToNSSet(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeToNSSet()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSSetAnyObjectToString() {
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
	let nativeString = nsString as String
	let nsSet = createNSSet()

  var result : Bool?
  for _ in 0 ..< 10_000 {
    if let nativeSet : Set<String> = conditionalCast(nsSet) {
       result = nativeSet.contains(nativeString)
    }
  }
	CheckResults(result != nil && result!, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSSetAnyObjectToString(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSSetAnyObjectToString()
  }
}

@inline(never)
func testObjectiveCBridgeFromNSSetAnyObjectToStringForced() {
  let nsSet = createNSSet()
  let nsString = NSString(cString: "NSString that does not fit in tagged pointer", encoding: NSUTF8StringEncoding)!
	let nativeString = nsString as String

  var result : Bool?
  for _ in 0 ..< 10_000 {
    if let nativeSet : Set<String> = forcedCast(nsSet) {
       result = nativeSet.contains(nativeString)
    }
  }
	CheckResults(result != nil && result!, "Expected results did not match")
}

@inline(never)
public func run_ObjectiveCBridgeFromNSSetAnyObjectToStringForced(N: Int) {
  for _ in 0 ..< N {
    testObjectiveCBridgeFromNSSetAnyObjectToStringForced()
  }
}
