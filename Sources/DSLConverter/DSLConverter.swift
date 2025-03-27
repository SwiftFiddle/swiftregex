import Foundation
@testable import _RegexParser
@testable @_spi(RegexBuilder) import _StringProcessing
@testable @_spi(PatternConverter) import _StringProcessing

struct DSLConverter {
  func convert(_ pattern: String, matchingOptions: [String] = []) throws -> String {
    let ast = try _RegexParser.parse(pattern, .traditional)
    var builderDSL = renderAsBuilderDSL(ast: ast)
    if builderDSL.last == "\n" {
      builderDSL = String(builderDSL.dropLast())
    }

    if matchingOptions.contains("m") {
      builderDSL.append("\n")
      builderDSL.append(".anchorsMatchLineEndings()")
    }
    if matchingOptions.contains("i") {
      builderDSL.append("\n")
      builderDSL.append(".ignoresCase()")
    }
    if matchingOptions.contains("s") {
      builderDSL.append("\n")
      builderDSL.append(".dotMatchesNewlines()")
    }
    if matchingOptions.contains("asciiOnlyWordCharacters") {
      builderDSL.append("\n")
      builderDSL.append(".asciiOnlyWordCharacters()")
    }
    if matchingOptions.contains("asciiOnlyDigits") {
      builderDSL.append("\n")
      builderDSL.append(".asciiOnlyDigits()")
    }
    if matchingOptions.contains("asciiOnlyWhitespace") {
      builderDSL.append("\n")
      builderDSL.append(".asciiOnlyWhitespace()")
    }
    if matchingOptions.contains("asciiOnlyCharacterClasses") {
      builderDSL.append("\n")
      builderDSL.append(".asciiOnlyCharacterClasses()")
    }
    builderDSL.append("\n")

    return builderDSL
  }
}
