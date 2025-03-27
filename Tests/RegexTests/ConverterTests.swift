import Foundation
import XCTest
@testable import DSLConverter

class ConverterTests: XCTestCase {
  func testConvertPattern() throws {
    do {
      let converter = DSLConverter()
      let builderDSL = try converter.convert(#"gray|grey"#)
      print(builderDSL)
    }
    do {
      let converter = DSLConverter()
      let builderDSL = try converter.convert(#"\b(?:[a-eg-z]|f(?!oo))\w*\b"#)
      print(builderDSL)
    }
  }
}
