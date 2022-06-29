import Foundation
@testable import _RegexParser
@testable @_spi(RegexBuilder) import _StringProcessing
@testable @_spi(PatternConverter) import _StringProcessing

struct DSLConverter {
    func convert(_ pattern: String) throws -> String {
        let ast = try _RegexParser.parse(pattern, .syntactic, .traditional)
        let builderDSL = renderAsBuilderDSL(ast: ast)
        return builderDSL
    }
}
