import Foundation

@testable import _RegexParser
@testable @_spi(RegexBenchmark) import _StringProcessing

struct Debugger {
  func run(pattern: String, text: String, matchingOptions: [String] = [], context: Debugger.Context) throws {
    var inlineFlags = ""
    if matchingOptions.contains("m") { inlineFlags += "m" }
    if matchingOptions.contains("i") { inlineFlags += "i" }
    if matchingOptions.contains("s") { inlineFlags += "s" }
    let effectivePattern = inlineFlags.isEmpty ? pattern : "(?\(inlineFlags))" + pattern
    let ast = try _RegexParser.parse(effectivePattern, .traditional)

    var sequence = [AST.MatchingOption]()
    if matchingOptions.contains("asciiOnlyWordCharacters") {
      sequence.append(.init(.asciiOnlyWord, location: .fake))
    }
    if matchingOptions.contains("asciiOnlyDigits") {
      sequence.append(.init(.asciiOnlyDigit, location: .fake))
    }
    if matchingOptions.contains("asciiOnlyWhitespace") {
      sequence.append(.init(.asciiOnlySpace, location: .fake))
    }
    if matchingOptions.contains("asciiOnlyCharacterClasses") {
      sequence.append(.init(.asciiOnlyPOSIXProps, location: .fake))
    }
    if matchingOptions.contains("matchingSemantics:unicodeScalar") {
      sequence.append(.init(.unicodeScalarSemantics, location: .fake))
    } else {
      sequence.append(.init(.graphemeClusterSemantics, location: .fake))
    }
    if matchingOptions.contains("repetitionBehavior:reluctant") {
      sequence.append(.init(.reluctantByDefault, location: .fake))
    } else if matchingOptions.contains("repetitionBehavior:possessive") {
      sequence.append(.init(.possessiveByDefault, location: .fake))
    }

    var options = MatchingOptions()
    options.apply(AST.MatchingOptionSequence(adding: sequence))

    let program = try compile(ast, options: options)

    context.instructions = program.instructions.map {
      $0.description
    }

    let inputRange = text.startIndex..<text.endIndex

    var cpu = Processor(
      program: program,
      input: text,
      subjectBounds: inputRange,
      searchBounds: inputRange,
      matchMode: .partialFromFront
    )

    do {
      _ = try Executor<AnyRegexOutput>._firstMatch(
        program,
        using: &cpu,
        context: context
      )
    } catch {}
  }

  func compile(_ ast: AST, options: MatchingOptions) throws -> MEProgram {
    let compiler = Compiler(tree: ast.dslTree, compileOptions: [.enableMetrics])
    compiler.options = options
    return try compiler.emit()
  }

  struct Metrics: Codable {
    var instructions: [String]
    var programCounter: Int

    var stepCount: Int
    var step: Int

    var totalCycleCount: Int
    var resets: Int
    var backtracks: Int

    var traces: [Trace]
    var failure: Location

    var matchOptions: [String]?
  }

  struct Trace: Codable {
    let location: Location
  }

  struct Location: Codable {
    let start: Int
    let end: Int
  }
}
