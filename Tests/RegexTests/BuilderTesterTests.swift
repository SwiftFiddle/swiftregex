import Foundation
import XCTest
@testable import BuilderTester

class BuilderTesterTests: XCTestCase {
    @MainActor
    func testBuilderTest() throws {
        CommandLine.arguments.removeAll()
        CommandLine.arguments.append("BuilderTester")
        CommandLine.arguments.append(
            """
            let kind = Reference(Substring.self)
            let date = Reference(Substring.self)
            Regex {
              Capture(as: kind) {
                ChoiceOf {
                  "CREDIT"
                  "DEBIT"
                }
              }
              OneOrMore(.whitespace)
              Capture(as: date) {
                Regex {
                  Repeat(1...2) {
                    One(.digit)
                  }
                  "/"
                  Repeat(1...2) {
                    One(.digit)
                  }
                  "/"
                  Repeat(count: 4) {
                    One(.digit)
                  }
                }
              }
            }
            """
        )
        CommandLine.arguments.append(
            """
            KIND      DATE          INSTITUTION                AMOUNT
            ----------------------------------------------------------------
            CREDIT    03/01/2022    Payroll from employer      $200.23
            CREDIT    03/03/2022    Suspect A                  $2,000,000.00
            DEBIT     03/03/2022    Ted's Pet Rock Sanctuary   $2,000,000.00
            DEBIT     03/05/2022    Doug's Dugout Dogs         $33.27
            DEBIT     06/03/2022    Oxford Comma Supply Ltd.   £57.33
            """
        )
        try Main.main()
    }
}
