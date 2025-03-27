import Foundation
import XCTest
@testable import ExpressionParser

class ParserTests: XCTestCase {
  func testParseExpression() throws {
    do {
      var parser = ExpressionParser(pattern: #"a(?R)?b"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+(?(?=regex)then|else(?(?=regex)then|else))(a)^(START)?\d+(?(1)END|\b)"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^[^<>]*(((?'Open'<)[^<>]*)+((?'Close-Open'>)[^<>]*)+)*(?(Open)(?!))$"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"hello"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gray|grey"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gr(a|e)y"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"gr[ae]y"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"colou?r"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"rege(x(es)?|xps?)"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"go*gle"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"go+gle"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"g(oog)+le"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3}"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3,6}"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"z{3,}"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[Bb]rainf\*\*k"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d{5}(-\d{4})?"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"1\d{10}"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[2-9]|[12]\d|3[0-6]"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"Hello\nworld"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"mi.....ft"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\d+(\.\d\d)?"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[^i*&2@]"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"//[^\r\n]*[\r\n]"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^dog"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"dog$"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"^dog$"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"\w++\d\d\w+"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"<(\w+)>[^<]*</\1>"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"Hillary(?=\s+Clinton)"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"q(?!u)"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?<=-)\p{L}+"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"[\x41-\x45]{3}"#)
      try parser.parse()
      print(parser.tokens)
    }
    do {
      var parser = ExpressionParser(pattern: #"(?(?=regex)then|else)"#)
      try parser.parse()
      print(parser.tokens)
    }
  }
}
