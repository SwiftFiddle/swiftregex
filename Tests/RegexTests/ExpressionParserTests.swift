import Foundation
import XCTest
@testable import ExpressionParser

class ParserTests: XCTestCase {
  func testParseExpression() {
    do {
      var parser = ExpressionParser(pattern: #"a(?R)?b"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+(?(?=regex)then|else(?(?=regex)then|else))(a)^(START)?\d+(?(1)END|\b)"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^[^<>]*(((?'Open'<)[^<>]*)+((?'Close-Open'>)[^<>]*)+)*(?(Open)(?!))$"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"hello"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gray|grey"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gr(a|e)y"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gr[ae]y"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"colou?r"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"rege(x(es)?|xps?)"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"go*gle"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"go+gle"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"g(oog)+le"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3}"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3,6}"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3,}"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[Bb]rainf\*\*k"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d{5}(-\d{4})?"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"1\d{10}"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[2-9]|[12]\d|3[0-6]"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"Hello\nworld"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"mi.....ft"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+(\.\d\d)?"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[^i*&2@]"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"//[^\r\n]*[\r\n]"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^dog"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"dog$"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^dog$"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\w++\d\d\w+"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"<(\w+)>[^<]*</\1>"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"Hillary(?=\s+Clinton)"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"q(?!u)"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?<=-)\p{L}+"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[\x41-\x45]{3}"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?(?=regex)then|else)"#)
      parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?<word>\w+)\W+(?<-word>\w+)"#)
      parser.parse()
      print(parser.tokens)
    }
  }
}
