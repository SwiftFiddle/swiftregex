import Foundation
@testable import _RegexParser

struct DSLParser {
    func parse(_ pattern: String) throws -> [Token] {
        let ast = try _RegexParser.parse(pattern, .traditional)

        var printer = PrettyPrinter()
        printer.printAsPattern(ast)
        _ = printer.finish()

        return printer.locationMappings.map { (sourceLocation, patternLocation) in
            Token(
                sourceLocation: Location(start: sourceLocation.start, end: sourceLocation.end),
                patternLocation: Location(
                    start: patternLocation.start.utf16Offset(in: pattern),
                    end: patternLocation.end.utf16Offset(in: pattern)
                )
            )
        }
    }
}

struct Token: Codable {
    let sourceLocation: Location
    let patternLocation: Location
}

struct Location: Codable {
    let start: Int
    let end: Int
}
