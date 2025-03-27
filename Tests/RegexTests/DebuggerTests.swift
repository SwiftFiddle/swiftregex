import Foundation
import XCTest
@testable import Debugger

class DebuggerTests: XCTestCase {
  func testDebugPattern01() throws {
    let pattern = #"a(b|c)"#
    let text = "ac"

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func testDebugPattern02() throws {
    let pattern = #".*b"#
    let text = "abcdefgh"

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func testDebugPattern03() throws {
    let pattern = #"a"#
    let text = "a"

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount
    print("stepCount: \(stepCount)")

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func testDebugPattern04() throws {
    let pattern = #"a"#
    let text = "ab"

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount
    print("stepCount: \(stepCount)")

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func testDebugPattern05() throws {
    let pattern = #"a"#
    let text = "ba"

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount
    print("stepCount: \(stepCount)")

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func testDebugPattern06() throws {
    let pattern = #"this|that|the"#
    let text = "The theory that the mathematician proposed about the threshold of the universe was both innovative and controversial."

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount
    print("stepCount: \(stepCount)")

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func testDebugPattern07() throws {
    let pattern = #"th(?:e|is|at)"#
    let text = "The theory that the mathematician proposed about the threshold of the universe was both innovative and controversial."

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount
    print("stepCount: \(stepCount)")

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func testDebugPattern08() throws {
    let pattern = #"<<<<<<< HEAD"#
    let text = """
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    If you have questions, please
    <<<<<<< HEAD
    open an issue
    =======
    ask your question in IRC.
    >>>>>>> branch-a
    """

    try run(pattern: pattern, text: text, matchingOptions: [])
    let stepCount = Context.shared.stepCount
    print("stepCount: \(stepCount)")

    let context = Context.shared
    for i in 1...stepCount {
      try run(pattern: pattern, text: text, matchingOptions: [], until: i)
      print("step: \(context.stepCount), start: \(context.start), current: \(context.current), \(text[text.index(text.startIndex, offsetBy: context.start)..<text.index(text.startIndex, offsetBy: context.current)])")
    }
  }

  func run(pattern: String, text: String, matchingOptions: [String] = [], until step: Int? = nil) throws {
    let context = Context.shared
    context.reset()
    context.breakPoint = step

    let debugger = Debugger()
    try debugger.run(pattern: pattern, text: text, matchingOptions: matchingOptions)
  }
}
