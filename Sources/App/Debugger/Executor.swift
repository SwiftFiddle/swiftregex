@testable import _RegexParser
@testable import _StringProcessing

enum Executor<Output> {
  static func prefixMatch(
    _ program: MEProgram,
    _ input: String,
    subjectBounds: Range<String.Index>,
    searchBounds: Range<String.Index>,
    context: Debugger.Context
  ) throws -> Regex<Output>.Match? {
    try Executor._run(
      program,
      input,
      subjectBounds: subjectBounds,
      searchBounds: searchBounds,
      mode: .partialFromFront,
      context: context
    )
  }

  static func wholeMatch(
    _ program: MEProgram,
    _ input: String,
    subjectBounds: Range<String.Index>,
    searchBounds: Range<String.Index>,
    context: Debugger.Context
  ) throws -> Regex<Output>.Match? {
    try Executor._run(
      program,
      input,
      subjectBounds: subjectBounds,
      searchBounds: searchBounds,
      mode: .wholeString,
      context: context
    )
  }

  static func firstMatch(
    _ program: MEProgram,
    _ input: String,
    subjectBounds: Range<String.Index>,
    searchBounds: Range<String.Index>,
    context: Debugger.Context
  ) throws -> Regex<Output>.Match? {
    var cpu = Processor(
      program: program,
      input: input,
      subjectBounds: subjectBounds,
      searchBounds: searchBounds,
      matchMode: .partialFromFront
    )
    return try Executor._firstMatch(
      program,
      using: &cpu,
      context: context
    )
  }

  static func _firstMatch(
    _ program: MEProgram,
    using cpu: inout Processor,
    context: Debugger.Context
  ) throws -> Regex<Output>.Match? {
    let isGraphemeSemantic = program.initialOptions.semanticLevel == .graphemeCluster

    var low = cpu.searchBounds.lowerBound
    let high = cpu.searchBounds.upperBound
    while true {
      if let m = try Executor._run(program, &cpu, context) {
        return m
      }
      // Fast-path for start-anchored regex
      if program.canOnlyMatchAtStart {
        return nil
      }
      if low == high { return nil }
      if isGraphemeSemantic {
        cpu.input.formIndex(after: &low)
      } else {
        cpu.input.unicodeScalars.formIndex(after: &low)
      }
      guard low <= high else {
        return nil
      }
      cpu.reset(currentPosition: low, searchBounds: cpu.searchBounds)
    }
  }
}

extension Executor {
  static func _run(
    _ program: MEProgram,
    _ input: String,
    subjectBounds: Range<String.Index>,
    searchBounds: Range<String.Index>,
    mode: MatchMode,
    context: Debugger.Context
  ) throws -> Regex<Output>.Match? {
    var cpu = Processor(
      program: program,
      input: input,
      subjectBounds: subjectBounds,
      searchBounds: searchBounds,
      matchMode: mode)
    return try _run(program, &cpu, context)
  }

  static func _run(
    _ program: MEProgram,
    _ cpu: inout Processor,
    _ context: Debugger.Context
  ) throws -> Regex<Output>.Match? {
    let startPosition = cpu.currentPosition
    context.start = startPosition.utf16Offset(in: cpu.input)
    guard let endIdx = try cpu.run(context) else {
      return nil
    }
    let range = startPosition..<endIdx

    let anyRegexOutput = AnyRegexOutput(
      input: cpu.input, elements: []
    )
    return .init(anyRegexOutput: anyRegexOutput, range: range)
  }}

extension Processor {
  fileprivate mutating func run(_ context: Debugger.Context) throws -> Input.Index? {
    if self.state == .fail {
      if let e = failureReason {
        throw e
      }
      return nil
    }
    assert(isReset())
    while true {
      context.programCounter = controller.pc.rawValue

      switch self.state {
      case .accept:
        return self.currentPosition
      case .fail:
        if let e = failureReason {
          throw e
        }
        return nil
      case .inProgress:
        let failurePosition = currentPosition.utf16Offset(in: input)

        self.cycle()

        context.stepCount += 1
        context.current = currentPosition.utf16Offset(in: input)
        context.failurePosition = failurePosition
#if PROCESSOR_MEASUREMENTS_ENABLED
        context.totalCycleCount = metrics.cycleCount
        context.resets = metrics.resets
        context.backtracks = metrics.backtracks
#endif
        if context.stepCount == context.breakPoint {
          throw CancellationError()
        }
      }
    }
  }
}
