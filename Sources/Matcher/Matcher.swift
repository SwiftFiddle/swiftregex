import Foundation
@testable @_spi(RegexBuilder) import _StringProcessing

struct Matcher {
  static func match(pattern: String, text: String, matchingOptions: [String] = []) throws -> [Match] {
    let regex = try Regex(pattern)
      .anchorsMatchLineEndings(matchingOptions.contains("m"))
      .ignoresCase(matchingOptions.contains("i"))
      .dotMatchesNewlines(matchingOptions.contains("s"))
      .asciiOnlyWordCharacters(matchingOptions.contains("asciiOnlyWordCharacters"))
      .asciiOnlyDigits(matchingOptions.contains("asciiOnlyDigits"))
      .asciiOnlyWhitespace(matchingOptions.contains("asciiOnlyWhitespace"))
      .asciiOnlyCharacterClasses(matchingOptions.contains("asciiOnlyCharacterClasses"))

    let matches = matchingOptions.contains("g") ? text.matches(of: regex) : text.firstMatch(of: regex).flatMap { [$0] } ?? []
    return matches.map {
      let captures: [Group] = $0.lazy.elements.dropFirst().map {
        if let range = $0.range {
          return Group(
            location: Location(
              start: range.lowerBound.utf16Offset(in: text),
              end: range.upperBound.utf16Offset(in: text)
            ),
            value: String(text[range]),
            name: $0.name
          )
        } else {
          return Group(
            location: nil,
            value: nil,
            name: $0.name
          )
        }
      }
      return Match(
        location: Location(
          start: $0.range.lowerBound.utf16Offset(in: text),
          end: $0.range.upperBound.utf16Offset(in: text)
        ),
        value: String(text[$0.range]),
        captures: captures
      )
    }
  }
}

struct Match: Codable {
  let location: Location
  let value: String

  let captures: [Group]
}

struct Group: Codable {
  let location: Location?
  let value: String?
  let name: String?
}

struct Location: Codable {
  let start: Int
  let end: Int
}
