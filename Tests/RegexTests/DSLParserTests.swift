import Foundation
import XCTest
@testable import DSLParser

class DSLParserTests: XCTestCase {
    func testParseDSL() throws {
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"\d+a|b"#)
            print(tokens)
        }
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"gray|grey"#)
            print(tokens)
        }
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"a(?<name>)\d+"#)
            print(tokens)
        }
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"hello"#)
            print(tokens)
        }
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"gray|grey"#)
            print(tokens)
        }
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"\d+"#)
            print(tokens)
        }
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"\d+a"#)
            print(tokens)
        }
        do {
            let parser = DSLParser()
            let tokens = try parser.parse(#"\b(?:[a-eg-z]|f(?!oo))\w*\b"#)
            print(tokens)
        }
    }
}
