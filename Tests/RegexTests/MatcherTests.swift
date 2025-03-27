import Foundation
import XCTest
@testable import Matcher

class MatchTest: XCTestCase {
  func testMatch() throws {
    do {
      let pattern = #"[A-Z]\w+"#
      let text = """
            Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
            """

      let matches = try Matcher.match(pattern: pattern, text: text)
      print(matches)
    }
    do {
      let pattern = #"\d+"#
      let text = """
            KIND      DATE          INSTITUTION                AMOUNT
            ----------------------------------------------------------------
            CREDIT    03/01/2022    Payroll from employer      $200.23
            CREDIT    03/03/2022    Suspect A                  $2,000,000.00
            DEBIT     03/03/2022    Ted's Pet Rock Sanctuary   $2,000,000.00
            DEBIT     03/05/2022    Doug's Dugout Dogs         $33.27
            DEBIT     06/03/2022    Oxford Comma Supply Ltd.   £57.33
            """

      let matches = try Matcher.match(pattern: pattern, text: text)
      print(matches)
    }
    do {
      let pattern = #"((\d{3})(?:\.|-))?(\d{3})(?:\.|-)(\d{4})"#
      let text = """
            Call 555-1212 for info
            """

      let matches = try Matcher.match(pattern: pattern, text: text)
      print(matches)
    }
  }
}
