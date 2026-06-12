import Foundation

@testable import _RegexParser
@testable @_spi(RegexBuilder) import _StringProcessing

struct ExpressionParser {
  struct Modes {
    let matchingOptions: [String]

    var i: Bool { matchingOptions.contains("i") }
    var s: Bool { matchingOptions.contains("s") }
  }

  private(set) var tokens = [Token]()
  private(set) var diagnostics: Diagnostics?

  private let pattern: String
  private let matchingOptions: [String]
  private let modes: Modes

  private var depth = 0
  private var groupCount = 0

  init(pattern: String, matchingOptions: [String]) {
    self.pattern = pattern
    self.matchingOptions = matchingOptions
    modes = Modes(matchingOptions: matchingOptions)
  }

  mutating func parse() {
    let ast = _RegexParser.parseWithRecovery(pattern, .traditional)
    diagnostics = ast.diags
    emitNode(ast.root)
  }

  private mutating func emitNode(_ node: AST.Node) {
    switch node {
    case .alternation(let alt):
      emitAlternation(alt)
    case .concatenation(let concatenation):
      for node in concatenation.children {
        emitNode(node)
      }
    case .group(let group):
      emitGroup(group)
    case .conditional(let conditional):
      emitConditional(conditional)
    case .quantification(let quant):
      emitQuantification(quant)
    case .quote(let quote):
      emitQuote(quote)
    case .trivia(let trivia):
      emitTrivia(trivia)
    case .interpolation(let interpolation):
      emitInterpolation(interpolation)
    case .atom(let atom):
      emitAtom(atom)
    case .customCharacterClass(let ccc):
      emitCustomCharacterClass(ccc)
    case .absentFunction(let absentFunction):
      emitAbsentFunction(absentFunction)
    case .empty(let empty):
      emitEmpty(empty)
    }
  }

  private mutating func emitAlternation(_ alt: AST.Alternation) {
    let children = alt.children
    for node in children.dropLast() {
      emitNode(node)
    }

    for pipe in alt.pipes {
      tokens.append(
        Token(
          classes: ["alt"],
          location: Location(
            start: pipe.start.utf16Offset(in: pattern),
            end: pipe.end.utf16Offset(in: pattern)
          ),
          selection: Location(
            start: pipe.start.utf16Offset(in: pattern),
            end: pipe.end.utf16Offset(in: pattern)
          ),
          related: Related(
            location: Location(
              start: alt.startPosition.utf16Offset(in: pattern),
              end: alt.endPosition.utf16Offset(in: pattern)
            )
          ),
          tooltip: Tooltip(category: "quants", key: "alt")
        )
      )
    }

    emitNode(children.last!)
  }

  private mutating func emitGroup(_ group: AST.Group) {
    let category: String
    let key: String
    var substitution = [String: String]()

    switch group.kind.value {
    case .capture:
      groupCount += 1
      category = "groups"
      key = "group"
      substitution = ["{{group.num}}": "\(groupCount)"]
    case .namedCapture(let name):
      groupCount += 1
      category = "groups"
      key = "namedgroup"
      substitution = ["{{name}}": name.value]
    case .balancedCapture(_):
      groupCount += 1
      category = "groups"
      key = "balancedcapture"
    case .nonCapture:
      category = "groups"
      key = "noncapgroup"
    case .nonCaptureReset:
      category = "groups"
      key = "branchreset"
    case .atomicNonCapturing:
      category = "groups"
      key = "atomic"
    case .lookahead:
      category = "lookaround"
      key = "poslookahead"
    case .negativeLookahead:
      category = "lookaround"
      key = "neglookahead"
    case .nonAtomicLookahead:
      category = "lookaround"
      key = "nonatomicposlookahead"
    case .lookbehind:
      category = "lookaround"
      key = "poslookbehind"
    case .negativeLookbehind:
      category = "lookaround"
      key = "neglookbehind"
    case .nonAtomicLookbehind:
      category = "lookaround"
      key = "nonatomicposlookbehind"
    case .scriptRun:
      category = "lookaround"
      key = "scriptrun"
    case .atomicScriptRun:
      category = "lookaround"
      key = "atomicscriptrun"
    case .changeMatchingOptions(let opts):
      category = "other"
      key = "mode"
      var modeSet = Set<AST.MatchingOption>()
      let modeRemoving = opts.removing.filter { modeSet.insert($0).inserted }
      modeSet = Set<AST.MatchingOption>()
      let modeAdding = opts.adding.filter { modeSet.insert($0).inserted }.filter { !modeRemoving.contains($0) }
      let modeEnable = modeAdding.map { String(pattern[$0.location.range]) }
      let modeDisable = modeRemoving.map { String(pattern[$0.location.range]) }
      var modeDesc = ""
      if !modeEnable.isEmpty {
        let descs = modeEnable.map { ExpressionParser.flagDescription($0) }
        modeDesc += " Enables \(descs.joined(separator: ", "))."
      }
      if !modeDisable.isEmpty {
        let descs = modeDisable.map { ExpressionParser.flagDescription($0) }
        modeDesc += " Disables \(descs.joined(separator: ", "))."
      }
      substitution = [
        "{{~getDesc()}}": "Changes matching options for the enclosed group.",
        "{{~getModes()}}": modeDesc,
      ]
    }

    // Content
    tokens.append(
      Token(
        classes: ["group-\(depth)"],
        location: Location(
          start: group.startPosition.utf16Offset(in: pattern),
          end: group.endPosition.utf16Offset(in: pattern)
        )
      )
    )

    // Open parenthesis
    tokens.append(
      Token(
        classes: ["group", "group-\(depth)"],
        location: Location(
          start: group.kind.location.start.utf16Offset(in: pattern),
          end: group.kind.location.end.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: group.startPosition.utf16Offset(in: pattern),
          end: group.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: category, key: key, substitution: substitution)
      )
    )

    // Close parenthesis
    tokens.append(
      Token(
        classes: ["group", "group-\(depth)"],
        location: Location(
          start: group.child.location.end.utf16Offset(in: pattern),
          end: group.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: group.startPosition.utf16Offset(in: pattern),
          end: group.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: category, key: key, substitution: substitution)
      )
    )

    depth += 1
    for node in group.children {
      emitNode(node)
    }

    depth -= 1
  }

  private mutating func emitConditional(_ conditional: AST.Conditional) {
    let category: String
    let key: String
    var substitution = [String: String]()

    switch conditional.condition.kind {
    case .groupMatched(let ref):
      switch ref.kind {
      case .absolute(let n):
        category = "other"
        key = "conditionalgroup"
        substitution = ["{{name}}": "\(n)"]
      case .relative(let n):
        category = "other"
        key = "conditionalgroup"
        substitution = ["{{name}}": "\(n)"]
      case .named(let name):
        category = "other"
        key = "conditionalgroup"
        substitution = ["{{name}}": "\(name)"]
      }

      tokens.append(
        Token(
          classes: ["special"],
          location: Location(
            start: conditional.startPosition.utf16Offset(in: pattern),
            end: conditional.condition.location.end.utf16Offset(in: pattern) + 1
          ),
          selection: Location(
            start: conditional.startPosition.utf16Offset(in: pattern),
            end: conditional.endPosition.utf16Offset(in: pattern)
          ),
          tooltip: Tooltip(category: category, key: key, substitution: substitution)
        )
      )
    case .recursionCheck:
      break
    case .groupRecursionCheck(_):
      tokens.append(
        Token(
          classes: ["special"],
          location: Location(
            start: conditional.startPosition.utf16Offset(in: pattern),
            end: conditional.condition.location.end.utf16Offset(in: pattern) + 1
          ),
          selection: Location(
            start: conditional.startPosition.utf16Offset(in: pattern),
            end: conditional.endPosition.utf16Offset(in: pattern)
          ),
          tooltip: Tooltip(category: "other", key: "recursion")
        )
      )
    case .defineGroup:
      break
    case .pcreVersionCheck(_):
      break
    case .group(let group):
      tokens.append(
        Token(
          classes: ["special"],
          location: Location(
            start: conditional.startPosition.utf16Offset(in: pattern),
            end: conditional.condition.location.start.utf16Offset(in: pattern)
          ),
          selection: Location(
            start: conditional.startPosition.utf16Offset(in: pattern),
            end: conditional.endPosition.utf16Offset(in: pattern)
          ),
          tooltip: Tooltip(category: "other", key: "conditional")
        )
      )

      // Open parenthesis
      tokens.append(
        Token(
          classes: ["special"],
          location: Location(
            start: group.kind.location.start.utf16Offset(in: pattern),
            end: group.kind.location.end.utf16Offset(in: pattern)
          ),
          selection: Location(
            start: group.startPosition.utf16Offset(in: pattern),
            end: group.endPosition.utf16Offset(in: pattern)
          ),
          tooltip: Tooltip(category: "misc", key: "condition")
        )
      )

      // Close parenthesis
      tokens.append(
        Token(
          classes: ["special"],
          location: Location(
            start: group.child.location.end.utf16Offset(in: pattern),
            end: group.endPosition.utf16Offset(in: pattern)
          ),
          selection: Location(
            start: group.startPosition.utf16Offset(in: pattern),
            end: group.endPosition.utf16Offset(in: pattern)
          ),
          tooltip: Tooltip(category: "misc", key: "condition")
        )
      )

      for node in group.children {
        emitNode(node)
      }
    }

    emitNode(conditional.trueBranch)

    if let pipe = conditional.pipe {
      tokens.append(
        Token(
          classes: ["special"],
          location: Location(
            start: pipe.start.utf16Offset(in: pattern),
            end: pipe.end.utf16Offset(in: pattern)
          ),
          selection: Location(
            start: pipe.start.utf16Offset(in: pattern),
            end: pipe.end.utf16Offset(in: pattern)
          ),
          related: Related(
            location: Location(
              start: conditional.startPosition.utf16Offset(in: pattern),
              end: conditional.endPosition.utf16Offset(in: pattern)
            )
          ),
          tooltip: Tooltip(category: "misc", key: "conditionalelse")
        )
      )
    }

    emitNode(conditional.falseBranch)

    tokens.append(
      Token(
        classes: ["special"],
        location: Location(
          start: conditional.falseBranch.location.end.utf16Offset(in: pattern),
          end: conditional.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: conditional.startPosition.utf16Offset(in: pattern),
          end: conditional.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: "other", key: "conditional")
      )
    )
  }

  private mutating func emitQuantification(_ quant: AST.Quantification) {
    emitNode(quant.child)

    let substitution: [String: String]
    switch quant.amount.value {
    case .zeroOrMore:  // *
      substitution = ["{{getQuant()}}": "0 or more"]
    case .oneOrMore:  // +
      substitution = ["{{getQuant()}}": "1 or more"]
    case .zeroOrOne:  // ?
      substitution = ["{{getQuant()}}": "between 0 and 1"]
    case .exactly(let n):  // {n}
      substitution = ["{{getQuant()}}": String(pattern[n.location.range])]
    case .nOrMore(let n):  // {n,}
      substitution = ["{{getQuant()}}": "\(pattern[n.location.range]) or more"]
    case .upToN(let n):  // {,n}
      substitution = ["{{getQuant()}}": "between 0 and \(pattern[n.location.range])"]
    case .range(let n, let m):  // {n,m}
      substitution = ["{{getQuant()}}": "between \(pattern[n.location.range]) and \(pattern[m.location.range])"]
    }

    tokens.append(
      Token(
        classes: ["quant"],
        location: Location(
          start: quant.amount.location.start.utf16Offset(in: pattern),
          end: quant.amount.location.end.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: quant.amount.location.start.utf16Offset(in: pattern),
          end: quant.amount.location.end.utf16Offset(in: pattern)
        ),
        related: Related(
          location: Location(
            start: quant.startPosition.utf16Offset(in: pattern),
            end: quant.endPosition.utf16Offset(in: pattern)
          )
        ),
        tooltip: Tooltip(category: "quants", key: "quant", substitution: substitution)
      )
    )

    switch quant.kind.value {
    case .eager:
      break
    case .reluctant:
      tokens.append(
        Token(
          classes: ["lazy"],
          location: Location(
            start: quant.kind.location.start.utf16Offset(in: pattern),
            end: quant.kind.location.end.utf16Offset(in: pattern)
          ),
          selection: Location(
            start: quant.kind.location.start.utf16Offset(in: pattern),
            end: quant.kind.location.end.utf16Offset(in: pattern)
          ),
          related: Related(
            location: Location(
              start: quant.amount.location.start.utf16Offset(in: pattern),
              end: quant.amount.location.end.utf16Offset(in: pattern)
            )
          ),
          tooltip: Tooltip(category: "quants", key: "lazy")
        )
      )
    case .possessive:
      tokens.append(
        Token(
          classes: ["possessive"],
          location: Location(
            start: quant.kind.location.start.utf16Offset(in: pattern),
            end: quant.kind.location.end.utf16Offset(in: pattern)
          ),
          selection: Location(
            start: quant.kind.location.start.utf16Offset(in: pattern),
            end: quant.kind.location.end.utf16Offset(in: pattern)
          ),
          related: Related(
            location: Location(
              start: quant.amount.location.start.utf16Offset(in: pattern),
              end: quant.amount.location.end.utf16Offset(in: pattern)
            )
          ),
          tooltip: Tooltip(category: "quants", key: "possessive")
        )
      )
    }
  }

  private mutating func emitQuote(_ quote: AST.Quote) {
    tokens.append(
      Token(
        classes: ["esc"],
        location: Location(
          start: quote.startPosition.utf16Offset(in: pattern),
          end: quote.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: quote.startPosition.utf16Offset(in: pattern),
          end: quote.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: "escchars", key: "escsequence", substitution: ["{{value}}": quote.literal])
      )
    )
  }

  private mutating func emitTrivia(_ trivia: AST.Trivia) {
    tokens.append(
      Token(
        classes: ["comment"],
        location: Location(
          start: trivia.startPosition.utf16Offset(in: pattern),
          end: trivia.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: trivia.startPosition.utf16Offset(in: pattern),
          end: trivia.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: "other", key: "comment")
      )
    )
  }

  private mutating func emitInterpolation(_ interpolation: AST.Interpolation) {
    tokens.append(
      Token(
        classes: ["interpolation"],
        location: Location(
          start: interpolation.startPosition.utf16Offset(in: pattern),
          end: interpolation.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: interpolation.startPosition.utf16Offset(in: pattern),
          end: interpolation.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: "other", key: "interpolation")
      )
    )
  }

  private mutating func emitAtom(_ atom: AST.Atom) {
    let `class`: String
    let category: String
    let key: String
    var substitution = [String: String]()

    switch atom.kind {
    case .char(let c):
      let charcode = c.unicodeScalars.map { String(format: "U+%X", $0.value) }.joined(separator: " ")
      let charName = ExpressionParser.charDisplayName(c)

      let value = String(pattern[atom.location.range])
      if value.hasPrefix("\\") {
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = [
          "{{getChar()}}": charName,
          "{{code}}": charcode,
          "{{getInsensitive()}}": "Case \(modes.i ? "in" : "")sensitive",
        ]
      } else {
        `class` = "char"
        category = "misc"
        key = "char"
        substitution = [
          "{{getChar()}}": charName,
          "{{code}}": charcode,
          "{{getInsensitive()}}": "Case \(modes.i ? "in" : "")sensitive",
        ]
      }
    case .scalar(let scalar):
      let scalarName: String
      if let name = ExpressionParser.nonprintingCharNames[scalar.value.value] {
        scalarName = name
      } else {
        scalarName = #""\#(String(scalar.value))""#
      }
      `class` = "char"
      category = "misc"
      key = "char"
      substitution = [
        "{{getChar()}}": scalarName,
        "{{code}}": String(format: "U+%X", scalar.value.value),
        "{{getInsensitive()}}": "Case \(modes.i ? "in" : "")sensitive",
      ]
    case .scalarSequence(let scalarSequence):
      let scalars = scalarSequence.scalars
      let value = scalars.map { String($0.value) }.joined()
      let charcode = scalars.map { String(format: "U+%X", $0.value.value) }.joined(separator: " ")

      `class` = "char"
      category = "misc"
      key = "char"
      substitution = [
        "{{getChar()}}": #""\#(value)""#,
        "{{code}}": charcode,
        "{{getInsensitive()}}": "Case \(modes.i ? "in" : "")sensitive",
      ]
    case .property(let prop):
      `class` = "charclass"

      switch prop.kind {
      case .any:
        category = "misc"
        key = "any"
      case .assigned:
        category = "misc"
        key = "assigned"
      case .ascii:
        category = "misc"
        key = "ascii"
      case .generalCategory(let cat):
        let uniCat: String
        switch cat {
        case .other:
          uniCat = "Other"
        case .control:
          uniCat = "Control"
        case .format:
          uniCat = "Format"
        case .unassigned:
          uniCat = "Unassigned"
        case .privateUse:
          uniCat = "Private use"
        case .surrogate:
          uniCat = "Surrogate"
        case .letter:
          uniCat = "Letter"
        case .casedLetter:
          uniCat = "Cased letter"
        case .lowercaseLetter:
          uniCat = "Lower case letter"
        case .modifierLetter:
          uniCat = "Modifier letter"
        case .otherLetter:
          uniCat = "Other letter"
        case .titlecaseLetter:
          uniCat = "Title case letter"
        case .uppercaseLetter:
          uniCat = "Upper case letter"
        case .mark:
          uniCat = "Mark"
        case .spacingMark:
          uniCat = "Spacing mark"
        case .enclosingMark:
          uniCat = "Enclosing mark"
        case .nonspacingMark:
          uniCat = "Non-spacing mark"
        case .number:
          uniCat = "Number"
        case .decimalNumber:
          uniCat = "Decimal number"
        case .letterNumber:
          uniCat = "Letter number"
        case .otherNumber:
          uniCat = "Other number"
        case .punctuation:
          uniCat = "Punctuation"
        case .connectorPunctuation:
          uniCat = "Connector punctuation"
        case .dashPunctuation:
          uniCat = "Dash punctuation"
        case .closePunctuation:
          uniCat = "Close punctuation"
        case .finalPunctuation:
          uniCat = "Final punctuation"
        case .initialPunctuation:
          uniCat = "Initial punctuation"
        case .otherPunctuation:
          uniCat = "Other punctuation"
        case .openPunctuation:
          uniCat = "Open punctuation"
        case .symbol:
          uniCat = "Symbol"
        case .currencySymbol:
          uniCat = "Currency symbol"
        case .modifierSymbol:
          uniCat = "Modifier symbol"
        case .mathSymbol:
          uniCat = "Mathematical symbol"
        case .otherSymbol:
          uniCat = "Other symbol"
        case .separator:
          uniCat = "Separator"
        case .lineSeparator:
          uniCat = "Line separator"
        case .paragraphSeparator:
          uniCat = "Paragraph separator"
        case .spaceSeparator:
          uniCat = "Space separator"
        }
        category = "charclasses"
        key = "unicodecat"
        substitution = ["{{getUniCat()}}": uniCat]
      case .binary(let property, _):
        switch property {
        case .asciiHexDigit:
          break
        case .alphabetic:
          break
        case .bidiControl:
          break
        case .bidiMirrored:
          break
        case .cased:
          break
        case .compositionExclusion:
          break
        case .caseIgnorable:
          break
        case .changesWhenCasefolded:
          break
        case .changesWhenCasemapped:
          break
        case .changesWhenNFKCCasefolded:
          break
        case .changesWhenLowercased:
          break
        case .changesWhenTitlecased:
          break
        case .changesWhenUppercased:
          break
        case .dash:
          break
        case .deprecated:
          break
        case .defaultIgnorableCodePoint:
          break
        case .diacratic:
          break
        case .emojiModifierBase:
          break
        case .emojiComponent:
          break
        case .emojiModifier:
          break
        case .emoji:
          break
        case .emojiPresentation:
          break
        case .extender:
          break
        case .extendedPictographic:
          break
        case .fullCompositionExclusion:
          break
        case .graphemeBase:
          break
        case .graphemeExtended:
          break
        case .graphemeLink:
          break
        case .hexDigit:
          break
        case .hyphen:
          break
        case .idContinue:
          break
        case .ideographic:
          break
        case .idStart:
          break
        case .idsBinaryOperator:
          break
        case .idsTrinaryOperator:
          break
        case .joinControl:
          break
        case .logicalOrderException:
          break
        case .lowercase:
          break
        case .math:
          break
        case .noncharacterCodePoint:
          break
        case .otherAlphabetic:
          break
        case .otherDefaultIgnorableCodePoint:
          break
        case .otherGraphemeExtended:
          break
        case .otherIDContinue:
          break
        case .otherIDStart:
          break
        case .otherLowercase:
          break
        case .otherMath:
          break
        case .otherUppercase:
          break
        case .patternSyntax:
          break
        case .patternWhitespace:
          break
        case .prependedConcatenationMark:
          break
        case .quotationMark:
          break
        case .radical:
          break
        case .regionalIndicator:
          break
        case .softDotted:
          break
        case .sentenceTerminal:
          break
        case .terminalPunctuation:
          break
        case .unifiedIdiograph:
          break
        case .uppercase:
          break
        case .variationSelector:
          break
        case .whitespace:
          break
        case .xidContinue:
          break
        case .xidStart:
          break
        case .expandsOnNFC:
          break
        case .expandsOnNFD:
          break
        case .expandsOnNFKC:
          break
        case .expandsOnNFKD:
          break
        }
        category = "charclasses"
        key = "binary"
        substitution = ["{{value}}": "\(property)"]
      case .script(let script):
        category = "charclasses"
        key = "script"
        substitution = ["{{value}}": "\(script)"]
      case .scriptExtension(let scriptExt):
        category = "charclasses"
        key = "scriptextension"
        substitution = ["{{value}}": "\(scriptExt)"]
      case .named(let name):
        category = "charclasses"
        key = "named"
        substitution = ["{{value}}": "\(name)"]
      case .numericType(let numType):
        category = "charclasses"
        key = "numerictype"
        substitution = ["{{value}}": "\(numType)"]
      case .numericValue(let numValue):
        category = "charclasses"
        key = "numericvalue"
        substitution = ["{{value}}": "\(numValue)"]
      case .mapping(let mappingType, let mappingValue):
        category = "charclasses"
        key = "mapping"
        substitution = ["{{value}}": "\(mappingType)=\(mappingValue)"]
      case .ccc(let combiningClass):
        category = "charclasses"
        key = "ccc"
        substitution = ["{{value}}": "\(combiningClass)"]
      case .age(let major, let minor):
        category = "charclasses"
        key = "age"
        substitution = ["{{value}}": "\(major).\(minor)"]
      case .block(let block):
        category = "charclasses"
        key = "block"
        substitution = ["{{value}}": "\(block)"]
      case .posix(let property):
        switch property {
        case .alnum:
          break
        case .blank:
          break
        case .graph:
          break
        case .print:
          break
        case .word:
          break
        case .xdigit:
          break
        }
        category = "charclasses"
        key = "posixcharclass"
        substitution = ["{{value}}": "\(property)"]
      case .pcreSpecial(let pcre):
        category = "charclasses"
        key = "pcrespecial"
        substitution = ["{{value}}": "\(pcre)"]
      case .javaSpecial(let java):
        category = "charclasses"
        key = "javaspecial"
        substitution = ["{{value}}": "\(java)"]
      case .invalid(key: let k, value: let v):
        category = "charclasses"
        key = "invalid"
      }
    case .escaped(let escaped):
      switch escaped {
      case .alarm:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "ALARM", "{{code}}": "(bell, 0x07)"]
      case .escape:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "ESCAPE", "{{code}}": "(escape, 0x1B)"]
      case .formfeed:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "FORM FEED", "{{code}}": "(form feed, 0x0C)"]
      case .newline:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "LINE FEED", "{{code}}": "(ASCII 0x0A)"]
      case .carriageReturn:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "CARRIAGE RETURN", "{{code}}": "(ASCII 0x0D)"]
      case .tab:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "TAB", "{{code}}": "(ASCII 0x09)"]
      case .singleDataUnit:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "SINGLE DATA UNIT", "{{code}}": "N/A"]
      case .decimalDigit:
        `class` = "charclass"
        category = "charclasses"
        key = "digit"
      case .notDecimalDigit:
        `class` = "charclass"
        category = "charclasses"
        key = "notdigit"
      case .horizontalWhitespace:
        `class` = "charclass"
        category = "charclasses"
        key = "hwhitespace"
      case .notHorizontalWhitespace:
        `class` = "charclass"
        category = "charclasses"
        key = "nothwhitespace"
      case .notNewline:
        `class` = "charclass"
        category = "charclasses"
        key = "notlinebreak"
      case .newlineSequence:
        `class` = "charclass"
        category = "charclasses"
        key = "linebreak"
      case .whitespace:
        `class` = "charclass"
        category = "charclasses"
        key = "whitespace"
      case .notWhitespace:
        `class` = "charclass"
        category = "charclasses"
        key = "notwhitespace"
      case .verticalTab:
        `class` = "charclass"
        category = "charclasses"
        key = "vwhitespace"
      case .notVerticalTab:
        `class` = "charclass"
        category = "charclasses"
        key = "notvwhitespace"
      case .wordCharacter:
        `class` = "charclass"
        category = "charclasses"
        key = "word"
      case .notWordCharacter:
        `class` = "charclass"
        category = "charclasses"
        key = "notword"
      case .backspace:
        `class` = "esc"
        category = "misc"
        key = "escchar"
        substitution = ["{{getChar()}}": "BACKSPACE", "{{code}}": "(0x08)"]
      case .graphemeCluster:
        `class` = "charclass"
        category = "charclasses"
        key = "graphemecluster"
      case .wordBoundary:
        `class` = "anchor"
        category = "anchors"
        key = "wordboundary"
      case .notWordBoundary:
        `class` = "anchor"
        category = "anchors"
        key = "notwordboundary"
      case .startOfSubject:
        `class` = "anchor"
        category = "anchors"
        key = "bos"
      case .endOfSubjectBeforeNewline:
        `class` = "anchor"
        category = "anchors"
        key = "eos"
      case .endOfSubject:
        `class` = "anchor"
        category = "anchors"
        key = "abseos"
      case .firstMatchingPositionInSubject:
        `class` = "anchor"
        category = "anchors"
        key = "prevmatchend"
      case .resetStartOfMatch:
        `class` = "charclass"
        category = "lookaround"
        key = "keepout"
      case .trueAnychar:
        `class` = "charclass"
        category = "charclasses"
        key = "trueanychar"
      case .textSegment:
        `class` = "charclass"
        category = "charclasses"
        key = "textsegment"
      case .notTextSegment:
        `class` = "charclass"
        category = "charclasses"
        key = "nottextsegment"
      }
    case .keyboardControl(_):
      `class` = "charclass"
      category = "charclasses"
      key = "keyboardcontrol"
      substitution = ["{{value}}": String(pattern[atom.location.range])]
    case .keyboardMeta(_):
      `class` = "charclass"
      category = "charclasses"
      key = "keyboardmeta"
      substitution = ["{{value}}": String(pattern[atom.location.range])]
    case .keyboardMetaControl(_):
      `class` = "charclass"
      category = "charclasses"
      key = "keyboardmetacontrol"
      substitution = ["{{value}}": String(pattern[atom.location.range])]
    case .namedCharacter(let charName):
      `class` = "charclass"
      category = "charclasses"
      key = "namedcharacter"
      substitution = ["{{value}}": "\(charName)"]
    case .dot:
      `class` = "charclass"
      category = "charclasses"
      key = "dot"
      substitution = ["{{getDotAll()}}": "\(modes.s ? "including" : "except") line breaks"]
    case .caretAnchor:
      `class` = "anchor"
      category = "anchors"
      key = "bof"
    case .dollarAnchor:
      `class` = "anchor"
      category = "anchors"
      key = "eof"
    case .backreference(let ref):
      `class` = "ref"
      switch ref.kind {
      case .absolute(let n):
        category = "groups"
        key = "numref"
        substitution = ["{{group.num}}": "\(n)"]
      case .relative(let n):
        category = "groups"
        key = "numref"
        substitution = ["{{group.num}}": "\(n)"]
      case .named(let name):
        category = "groups"
        key = "namedref"
        substitution = ["{{group.name}}": name]
      }
    case .subpattern(let ref):
      if ref.kind.recursesWholePattern {
        `class` = "special"
        category = "other"
        key = "recursion"
      } else {
        `class` = "charclass"
        category = "charclasses"
        key = "subpattern"
      }
    case .callout(_):
      `class` = "charclass"
      category = "charclasses"
      key = "callout"
    case .backtrackingDirective(let directive):
      `class` = "charclass"

      switch directive.kind.value {
      case .accept:
        category = "charclasses"
        key = "accept"
      case .fail:
        category = "charclasses"
        key = "fail"
      case .mark:
        category = "charclasses"
        key = "mark"
      case .commit:
        category = "charclasses"
        key = "commit"
      case .prune:
        category = "charclasses"
        key = "prune"
      case .skip:
        category = "charclasses"
        key = "skip"
      case .then:
        category = "charclasses"
        key = "then"
      }
    case .changeMatchingOptions(let matchingOptionSequence):
      var set = Set<AST.MatchingOption>()
      let removing = matchingOptionSequence.removing.filter { set.insert($0).inserted }

      set = Set<AST.MatchingOption>()
      let adding = matchingOptionSequence.adding.filter { set.insert($0).inserted }.filter { !removing.contains($0) }

      let enable = adding.map { String(pattern[$0.location.range]) }
      let disable = removing.map { String(pattern[$0.location.range]) }
      var modes = ""
      if !enable.isEmpty {
        let descs = enable.map { ExpressionParser.flagDescription($0) }
        modes += " Enables \(descs.joined(separator: ", "))."
      }
      if !disable.isEmpty {
        let descs = disable.map { ExpressionParser.flagDescription($0) }
        modes += " Disables \(descs.joined(separator: ", "))."
      }

      `class` = "special"
      category = "other"
      key = "mode"
      substitution = [
        "{{~getDesc()}}": "Enables or disables modes for the remainder of the expression.",
        "{{~getModes()}}": modes,
      ]
    case .invalid:
      `class` = "charclass"
      category = "charclasses"
      key = "invalid"
    }

    tokens.append(
      Token(
        classes: [`class`],
        location: Location(
          start: atom.startPosition.utf16Offset(in: pattern),
          end: atom.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: atom.startPosition.utf16Offset(in: pattern),
          end: atom.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: category, key: key, substitution: substitution)
      )
    )
  }

  private mutating func emitCustomCharacterClass(_ ccc: AST.CustomCharacterClass) {
    let category: String
    let key: String

    switch ccc.start.value {
    case .normal:
      category = "charclasses"
      key = "set"
    case .inverted:
      category = "charclasses"
      key = "setnot"
    }

    tokens.append(
      Token(
        classes: ["set"],
        location: Location(
          start: ccc.start.location.start.utf16Offset(in: pattern),
          end: ccc.start.location.end.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: ccc.startPosition.utf16Offset(in: pattern),
          end: ccc.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: category, key: key)
      )
    )

    tokens.append(
      Token(
        classes: ["group-set"],
        location: Location(
          start: ccc.startPosition.utf16Offset(in: pattern),
          end: ccc.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: ccc.startPosition.utf16Offset(in: pattern),
          end: ccc.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: category, key: key)
      )
    )

    for member in ccc.members {
      switch member {
      case .custom(let custom):
        emitCustomCharacterClass(custom)
      case .range(let range):
        let lhs: String
        let rhs: String
        let dash = String(pattern[range.dashLoc.range])

        switch range.lhs.kind {
        case .char(let c):
          lhs = String(c)
        case .scalar(let scalar):
          lhs = String(scalar.value)
        case .scalarSequence(let scalarSequence):
          lhs = String(scalarSequence.scalarValues)
        case .property(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .escaped(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .keyboardControl(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .keyboardMeta(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .keyboardMetaControl(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .namedCharacter(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .dot:
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .caretAnchor:
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .dollarAnchor:
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .backreference(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .subpattern(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .callout(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .backtrackingDirective(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .changeMatchingOptions(_):
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        case .invalid:
          lhs = String(pattern[range.lhs.startPosition..<range.lhs.endPosition])
        }

        switch range.rhs.kind {
        case .char(let c):
          rhs = String(c)
        case .scalar(let scalar):
          rhs = String(scalar.value)
        case .scalarSequence(let scalarSequence):
          rhs = String(scalarSequence.scalarValues)
        case .property(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .escaped(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .keyboardControl(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .keyboardMeta(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .keyboardMetaControl(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .namedCharacter(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .dot:
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .caretAnchor:
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .dollarAnchor:
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .backreference(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .subpattern(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .callout(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .backtrackingDirective(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .changeMatchingOptions(_):
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        case .invalid:
          rhs = String(pattern[range.rhs.startPosition..<range.rhs.endPosition])
        }

        let lhscharcode = lhs.unicodeScalars.map { String(format: "U+%X", $0.value) }.joined(separator: " ")
        let rhscharcode = rhs.unicodeScalars.map { String(format: "U+%X", $0.value) }.joined(separator: " ")

        let substitution = [
          "{{getChar(prev)}}": #""\#(lhs)""#,
          "{{getChar(next)}}": #""\#(rhs)""#,
          "{{prev.code}}": #""\#(lhscharcode)""#,
          "{{next.code}}": #""\#(rhscharcode)""#,
          "{{getInsensitive()}}": "Case \(modes.i ? "in" : "")sensitive.",
        ]

        tokens.append(
          Token(
            classes: ["char"],
            location: Location(
              start: range.lhs.startPosition.utf16Offset(in: pattern),
              end: range.lhs.endPosition.utf16Offset(in: pattern)
            ),
            selection: Location(
              start: range.lhs.startPosition.utf16Offset(in: pattern),
              end: range.rhs.endPosition.utf16Offset(in: pattern)
            ),
            tooltip: Tooltip(category: "charclasses", key: "range", substitution: substitution)
          )
        )
        tokens.append(
          Token(
            classes: ["set"],
            location: Location(
              start: range.dashLoc.start.utf16Offset(in: pattern),
              end: range.dashLoc.end.utf16Offset(in: pattern)
            ),
            selection: Location(
              start: range.lhs.startPosition.utf16Offset(in: pattern),
              end: range.rhs.endPosition.utf16Offset(in: pattern)
            ),
            tooltip: Tooltip(category: "charclasses", key: "range", substitution: substitution)
          )
        )
        tokens.append(
          Token(
            classes: ["char"],
            location: Location(
              start: range.rhs.startPosition.utf16Offset(in: pattern),
              end: range.rhs.endPosition.utf16Offset(in: pattern)
            ),
            selection: Location(
              start: range.lhs.startPosition.utf16Offset(in: pattern),
              end: range.rhs.endPosition.utf16Offset(in: pattern)
            ),
            tooltip: Tooltip(category: "charclasses", key: "range", substitution: substitution)
          )
        )
      case .atom(let atom):
        emitAtom(atom)
      case .quote(let quote):
        emitQuote(quote)
      case .trivia(let trivia):
        emitTrivia(trivia)
      case .setOperation(_, _, _):
        break
      }
    }

    tokens.append(
      Token(
        classes: ["set"],
        location: Location(
          start: ccc.endPosition.utf16Offset(in: pattern) - 1,
          end: ccc.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: ccc.startPosition.utf16Offset(in: pattern),
          end: ccc.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: category, key: key)
      )
    )
  }

  private mutating func emitAbsentFunction(_ absentFunction: AST.AbsentFunction) {
    switch absentFunction.kind {
    case .repeater(_):
      break
    case .expression(let absentee, let pipe, let expr):
      break
    case .stopper(_):
      break
    case .clearer:
      break
    }

    // Content
    tokens.append(
      Token(
        classes: ["group-0"],
        location: Location(
          start: absentFunction.startPosition.utf16Offset(in: pattern),
          end: absentFunction.endPosition.utf16Offset(in: pattern)
        )
      )
    )

    // Open parenthesis
    tokens.append(
      Token(
        classes: ["group", "group-0"],
        location: Location(
          start: absentFunction.start.start.utf16Offset(in: pattern),
          end: absentFunction.start.end.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: absentFunction.startPosition.utf16Offset(in: pattern),
          end: absentFunction.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: "groups", key: "absentfunction")
      )
    )

    // Close parenthesis
    tokens.append(
      Token(
        classes: ["group", "group-0"],
        location: Location(
          start: absentFunction.endPosition.utf16Offset(in: pattern),
          end: absentFunction.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: absentFunction.startPosition.utf16Offset(in: pattern),
          end: absentFunction.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: "groups", key: "absentfunction")
      )
    )
  }

  private mutating func emitEmpty(_ empty: AST.Empty) {
    tokens.append(
      Token(
        classes: ["empty"],
        location: Location(
          start: empty.startPosition.utf16Offset(in: pattern),
          end: empty.endPosition.utf16Offset(in: pattern)
        ),
        selection: Location(
          start: empty.startPosition.utf16Offset(in: pattern),
          end: empty.endPosition.utf16Offset(in: pattern)
        ),
        tooltip: Tooltip(category: "empty", key: "empty")
      )
    )
  }

  private static let nonprintingCharNames: [UInt32: String] = [
    0x00: "NULL",
    0x01: "SOH",
    0x02: "STX",
    0x03: "ETX",
    0x04: "EOT",
    0x05: "ENQ",
    0x06: "ACK",
    0x07: "BELL",
    0x08: "BACKSPACE",
    0x09: "TAB",
    0x0A: "LINE FEED",
    0x0B: "VERTICAL TAB",
    0x0C: "FORM FEED",
    0x0D: "CARRIAGE RETURN",
    0x0E: "SHIFT OUT",
    0x0F: "SHIFT IN",
    0x10: "DLE",
    0x11: "DC1",
    0x12: "DC2",
    0x13: "DC3",
    0x14: "DC4",
    0x15: "NAK",
    0x16: "SYN",
    0x17: "ETB",
    0x18: "CAN",
    0x19: "EM",
    0x1A: "SUB",
    0x1B: "ESCAPE",
    0x1C: "FS",
    0x1D: "GS",
    0x1E: "RS",
    0x1F: "US",
    0x7F: "DELETE",
  ]

  private static func charDisplayName(_ c: Character) -> String {
    if let scalar = c.unicodeScalars.first, c.unicodeScalars.count == 1,
       let name = nonprintingCharNames[scalar.value] {
      return name
    }
    return #""\#(c)""#
  }

  private static func flagDescription(_ flag: String) -> String {
    switch flag {
    case "i": return "case-insensitive matching"
    case "m": return "multiline mode"
    case "s": return "single-line mode (dot matches newlines)"
    case "x": return "extended mode (ignore whitespace)"
    case "n": return "named captures only"
    case "J": return "allow duplicate named groups"
    case "U": return "ungreedy quantifiers by default"
    case "w": return "Unicode word boundaries"
    default: return "flag \"\(flag)\""
    }
  }
}

struct Token: Codable {
  let classes: [String]
  let location: Location
  let selection: Location?
  let related: Related?
  let tooltip: Tooltip?

  init(classes: [String], location: Location, selection: Location? = nil, related: Related? = nil, tooltip: Tooltip? = nil) {
    self.classes = classes
    self.location = location
    self.selection = selection
    self.related = related
    self.tooltip = tooltip
  }
}

extension Token: CustomStringConvertible {
  var description: String {
    #"\#(classes) \#(location)"#
  }
}

struct Location: Codable {
  let start: Int
  let end: Int
}

extension Location: CustomStringConvertible {
  var description: String {
    "\(start)-\(end)"
  }
}

struct Tooltip: Codable {
  let category: String
  let key: String
  let substitution: [String: String]

  init(category: String, key: String, substitution: [String: String] = [:]) {
    self.category = category
    self.key = key
    self.substitution = substitution
  }
}

extension Tooltip: CustomStringConvertible {
  var description: String {
    "\(category).\(key) \(substitution)"
  }
}

struct Related: Codable {
  let location: Location
}
