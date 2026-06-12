import Foundation

@testable import _RegexParser
@testable @_spi(RegexBuilder) import _StringProcessing
@testable @_spi(PatternConverter) import _StringProcessing

struct DSLSourceMapEntry: Codable {
  let patternStart: Int
  let patternEnd: Int
  let dslStart: Int
  let dslEnd: Int
}

struct DSLResult: Codable {
  let dsl: String
  let sourceMap: [DSLSourceMapEntry]
}

class DSLConverter {
  private(set) var diagnostics: Diagnostics?

  func convert(_ pattern: String, matchingOptions: [String] = []) throws -> String {
    convertWithSourceMap(pattern, matchingOptions: matchingOptions).dsl
  }

  func convertWithSourceMap(_ pattern: String, matchingOptions: [String] = []) -> DSLResult {
    let ast = _RegexParser.parseWithRecovery(pattern, .traditional)
    diagnostics = ast.diags

    var builderDSL = renderAsBuilderDSL(ast: ast)
    if builderDSL.last == "\n" {
      builderDSL = String(builderDSL.dropLast())
    }

    let sourceMap = generateSourceMap(ast: ast, dsl: builderDSL, pattern: pattern)

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
    if matchingOptions.contains("matchingSemantics:unicodeScalar") {
      builderDSL.append("\n")
      builderDSL.append(".matchingSemantics(.unicodeScalar)")
    }
    if matchingOptions.contains("repetitionBehavior:reluctant") {
      builderDSL.append("\n")
      builderDSL.append(".repetitionBehavior(.reluctant)")
    } else if matchingOptions.contains("repetitionBehavior:possessive") {
      builderDSL.append("\n")
      builderDSL.append(".repetitionBehavior(.possessive)")
    }
    if matchingOptions.contains("wordBoundaryKind:simple") {
      builderDSL.append("\n")
      builderDSL.append(".wordBoundaryKind(.simple)")
    }
    builderDSL.append("\n")

    return DSLResult(dsl: builderDSL, sourceMap: sourceMap)
  }

  // MARK: - Source Map Generation

  private func generateSourceMap(ast: AST, dsl: String, pattern: String) -> [DSLSourceMapEntry] {
    var entries: [DSLSourceMapEntry] = []
    var cursor = dsl.startIndex
    walkNode(ast.root, pattern: pattern, dsl: dsl, cursor: &cursor, entries: &entries)
    return entries
  }

  private func walkNode(
    _ node: AST.Node,
    pattern: String,
    dsl: String,
    cursor: inout String.Index,
    entries: inout [DSLSourceMapEntry]
  ) {
    switch node {
    case .alternation(let alt):
      recordBlock(
        "ChoiceOf",
        patternStart: alt.startPosition.utf16Offset(in: pattern),
        patternEnd: alt.endPosition.utf16Offset(in: pattern),
        dsl: dsl, cursor: &cursor, entries: &entries
      )
      for child in alt.children {
        walkNode(child, pattern: pattern, dsl: dsl, cursor: &cursor, entries: &entries)
      }

    case .concatenation(let concat):
      walkConcatenation(
        Array(concat.children), pattern: pattern, dsl: dsl,
        cursor: &cursor, entries: &entries
      )

    case .group(let group):
      if let keyword = groupKeyword(group) {
        recordBlock(
          keyword,
          patternStart: group.startPosition.utf16Offset(in: pattern),
          patternEnd: group.endPosition.utf16Offset(in: pattern),
          dsl: dsl, cursor: &cursor, entries: &entries
        )
      }
      walkNode(group.child, pattern: pattern, dsl: dsl, cursor: &cursor, entries: &entries)

    case .quantification(let quant):
      if let keyword = quantKeyword(quant) {
        recordBlock(
          keyword,
          patternStart: quant.startPosition.utf16Offset(in: pattern),
          patternEnd: quant.endPosition.utf16Offset(in: pattern),
          dsl: dsl, cursor: &cursor, entries: &entries
        )
      }
      walkNode(quant.child, pattern: pattern, dsl: dsl, cursor: &cursor, entries: &entries)

    case .atom(let atom):
      let keywords = atomKeywords(atom, pattern: pattern)
      for keyword in keywords {
        if recordLine(
          keyword,
          patternStart: atom.startPosition.utf16Offset(in: pattern),
          patternEnd: atom.endPosition.utf16Offset(in: pattern),
          dsl: dsl, cursor: &cursor, entries: &entries
        ) { break }
      }

    case .customCharacterClass(let ccc):
      walkCustomCharacterClass(ccc, pattern: pattern, dsl: dsl, cursor: &cursor, entries: &entries)

    case .quote(let quote):
      let text = quote.literal
      if !text.isEmpty {
        let escaped = escapeLiteral(text)
        recordLine(
          "\"\(escaped)\"",
          patternStart: quote.startPosition.utf16Offset(in: pattern),
          patternEnd: quote.endPosition.utf16Offset(in: pattern),
          dsl: dsl, cursor: &cursor, entries: &entries
        )
      }

    default:
      break
    }
  }

  private func walkConcatenation(
    _ children: [AST.Node],
    pattern: String,
    dsl: String,
    cursor: inout String.Index,
    entries: inout [DSLSourceMapEntry]
  ) {
    var i = 0
    while i < children.count {
      if case .atom(let atom) = children[i], isLiteralChar(atom) {
        var chars = ""
        let runStart = i
        while i < children.count,
              case .atom(let a) = children[i],
              isLiteralChar(a) {
          chars += literalCharString(a) ?? ""
          i += 1
        }
        let escaped = escapeLiteral(chars)
        let quoted = "\"\(escaped)\""
        recordLine(
          quoted,
          patternStart: children[runStart].location.start.utf16Offset(in: pattern),
          patternEnd: children[i - 1].location.end.utf16Offset(in: pattern),
          dsl: dsl, cursor: &cursor, entries: &entries
        )
      } else {
        walkNode(children[i], pattern: pattern, dsl: dsl, cursor: &cursor, entries: &entries)
        i += 1
      }
    }
  }

  private func walkCustomCharacterClass(
    _ ccc: AST.CustomCharacterClass,
    pattern: String,
    dsl: String,
    cursor: inout String.Index,
    entries: inout [DSLSourceMapEntry]
  ) {
    let patternStart = ccc.startPosition.utf16Offset(in: pattern)
    let patternEnd = ccc.endPosition.utf16Offset(in: pattern)

    if let _ = findKeyword("CharacterClass", in: dsl, from: cursor) {
      recordLine(
        "CharacterClass",
        patternStart: patternStart,
        patternEnd: patternEnd,
        dsl: dsl, cursor: &cursor, entries: &entries
      )
    } else if let _ = findKeyword(".anyOf(", in: dsl, from: cursor) {
      recordLine(
        ".anyOf(",
        patternStart: patternStart,
        patternEnd: patternEnd,
        dsl: dsl, cursor: &cursor, entries: &entries
      )
    }
  }

  // MARK: - Keyword Mapping

  private func groupKeyword(_ group: AST.Group) -> String? {
    switch group.kind.value {
    case .capture:
      return "Capture"
    case .namedCapture:
      return "Capture"
    case .nonCapture:
      return nil
    case .lookahead:
      return "Lookahead"
    case .negativeLookahead:
      return "NegativeLookahead"
    case .lookbehind:
      return "Lookbehind"
    case .negativeLookbehind:
      return "NegativeLookbehind"
    case .atomicNonCapturing:
      return "Local"
    default:
      return nil
    }
  }

  private func quantKeyword(_ quant: AST.Quantification) -> String? {
    switch quant.amount.value {
    case .zeroOrMore:
      return "ZeroOrMore"
    case .oneOrMore:
      return "OneOrMore"
    case .zeroOrOne:
      return "Optionally"
    case .exactly, .nOrMore, .upToN, .range:
      return "Repeat"
    }
  }

  private func atomKeywords(_ atom: AST.Atom, pattern: String) -> [String] {
    switch atom.kind {
    case .dot:
      return [".any"]
    case .escaped(let esc):
      switch esc {
      case .decimalDigit: return [".digit"]
      case .notDecimalDigit: return [".digit.inverted"]
      case .wordCharacter: return [".word"]
      case .notWordCharacter: return [".word.inverted"]
      case .whitespace: return [".whitespace"]
      case .notWhitespace: return [".whitespace.inverted"]
      case .horizontalWhitespace: return [".horizontalWhitespace"]
      case .notHorizontalWhitespace: return [".horizontalWhitespace.inverted"]
      case .verticalTab: return [".verticalWhitespace"]
      case .notVerticalTab: return [".verticalWhitespace.inverted"]
      case .newlineSequence: return [".newlineSequence"]
      case .notNewline: return [".anyNonNewline"]
      case .wordBoundary: return ["Anchor.wordBoundary", #"/\b/"#]
      case .notWordBoundary: return ["Anchor.nonWordBoundary", #"/\B/"#]
      case .startOfSubject: return ["Anchor.startOfSubject", #"/\A/"#]
      case .endOfSubjectBeforeNewline: return ["Anchor.endOfSubjectBeforeNewline", #"/\Z/"#]
      case .endOfSubject: return ["Anchor.endOfSubject", #"/\z/"#]
      case .graphemeCluster: return [".anyGraphemeCluster"]
      case .newline: return [#""\n""#]
      case .carriageReturn: return [#""\r""#]
      case .tab: return [#""\t""#]
      default: return []
      }
    case .caretAnchor:
      return ["Anchor.startOfLine", "/^/"]
    case .dollarAnchor:
      return ["Anchor.endOfLine", "/$/"]
    case .backreference:
      return ["Reference"]
    default:
      return []
    }
  }

  // MARK: - Literal Character Helpers

  private func isLiteralChar(_ atom: AST.Atom) -> Bool {
    switch atom.kind {
    case .char: return true
    case .scalar: return true
    case .scalarSequence: return true
    default: return false
    }
  }

  private func literalCharString(_ atom: AST.Atom) -> String? {
    switch atom.kind {
    case .char(let c): return String(c)
    case .scalar(let scalar): return String(scalar.value)
    case .scalarSequence(let seq): return String(seq.scalarValues)
    default: return nil
    }
  }

  private func escapeLiteral(_ str: String) -> String {
    str
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
  }

  private func utf16Distance(in str: String, to index: String.Index) -> Int {
    str.utf16.distance(from: str.utf16.startIndex, to: index)
  }

  // MARK: - DSL Search Helpers

  private func findKeyword(_ keyword: String, in dsl: String, from cursor: String.Index) -> Range<String.Index>? {
    guard cursor < dsl.endIndex else { return nil }
    return dsl.range(of: keyword, range: cursor..<dsl.endIndex)
  }

  private func recordBlock(
    _ keyword: String,
    patternStart: Int,
    patternEnd: Int,
    dsl: String,
    cursor: inout String.Index,
    entries: inout [DSLSourceMapEntry]
  ) {
    guard let keywordRange = findKeyword(keyword, in: dsl, from: cursor) else { return }

    let lineStart = findLineStart(in: dsl, at: keywordRange.lowerBound)
    let lineEnd = findLineEnd(in: dsl, at: keywordRange.upperBound)

    var blockEnd: String.Index
    let restOfLine = dsl[keywordRange.upperBound..<lineEnd]
    if let braceStart = restOfLine.firstIndex(of: "{"),
       let braceEnd = findMatchingBrace(in: dsl, from: braceStart) {
      blockEnd = braceEnd
    } else {
      blockEnd = lineEnd
    }

    entries.append(DSLSourceMapEntry(
      patternStart: patternStart,
      patternEnd: patternEnd,
      dslStart: utf16Distance(in: dsl, to: lineStart),
      dslEnd: utf16Distance(in: dsl, to: blockEnd)
    ))

    cursor = keywordRange.upperBound
  }

  @discardableResult
  private func recordLine(
    _ keyword: String,
    patternStart: Int,
    patternEnd: Int,
    dsl: String,
    cursor: inout String.Index,
    entries: inout [DSLSourceMapEntry]
  ) -> Bool {
    guard let keywordRange = findKeyword(keyword, in: dsl, from: cursor) else { return false }

    let lineStart = findLineStart(in: dsl, at: keywordRange.lowerBound)
    let lineEnd = findLineEnd(in: dsl, at: keywordRange.upperBound)

    entries.append(DSLSourceMapEntry(
      patternStart: patternStart,
      patternEnd: patternEnd,
      dslStart: utf16Distance(in: dsl, to: lineStart),
      dslEnd: utf16Distance(in: dsl, to: lineEnd)
    ))

    cursor = keywordRange.upperBound
    return true
  }

  private func findMatchingBrace(in str: String, from openBrace: String.Index) -> String.Index? {
    var depth = 0
    var i = openBrace
    while i < str.endIndex {
      if str[i] == "{" { depth += 1 }
      if str[i] == "}" {
        depth -= 1
        if depth == 0 { return str.index(after: i) }
      }
      i = str.index(after: i)
    }
    return nil
  }

  private func findLineStart(in str: String, at index: String.Index) -> String.Index {
    var i = index
    while i > str.startIndex {
      let prev = str.index(before: i)
      if str[prev] == "\n" { return i }
      i = prev
    }
    return str.startIndex
  }

  private func findLineEnd(in str: String, at index: String.Index) -> String.Index {
    var i = index
    while i < str.endIndex {
      if str[i] == "\n" { return i }
      i = str.index(after: i)
    }
    return str.endIndex
  }
}
