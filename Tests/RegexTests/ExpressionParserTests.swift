import Foundation
import XCTest
@testable import ExpressionParser

class ParserTests: XCTestCase {
  func testParseExpression() {
    let options: [String] = []
    do {
      var parser = ExpressionParser(pattern: #"a(?R)?b"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+(?(?=regex)then|else(?(?=regex)then|else))(a)^(START)?\d+(?(1)END|\b)"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^[^<>]*(((?'Open'<)[^<>]*)+((?'Close-Open'>)[^<>]*)+)*(?(Open)(?!))$"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"hello"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gray|grey"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gr(a|e)y"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gr[ae]y"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"colou?r"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"rege(x(es)?|xps?)"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"go*gle"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"go+gle"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"g(oog)+le"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3}"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3,6}"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3,}"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[Bb]rainf\*\*k"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d{5}(-\d{4})?"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"1\d{10}"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[2-9]|[12]\d|3[0-6]"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"Hello\nworld"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"mi.....ft"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+(\.\d\d)?"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[^i*&2@]"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"//[^\r\n]*[\r\n]"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^dog"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"dog$"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^dog$"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\w++\d\d\w+"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"<(\w+)>[^<]*</\1>"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"Hillary(?=\s+Clinton)"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"q(?!u)"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?<=-)\p{L}+"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[\x41-\x45]{3}"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?(?=regex)then|else)"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?<word>\w+)\W+(?<-word>\w+)"#, matchingOptions: options)
      parser.parse()
      print(parser.tokens)
    }
  }
}
