import Foundation

extension Debugger {
  class Context {
    var instructions: [String] = []
    var programCounter = 0

    var stepCount = 0
    var breakPoint: Int?

    var start: Int = 0
    var current: Int = 0
    var failurePosition: Int = 0

    var totalCycleCount = 0
    var resets = 0
    var backtracks = 0

    init(stepCount: Int = 0, breakPoint: Int? = nil) {
      self.stepCount = stepCount
      self.breakPoint = breakPoint
    }

    func reset() {
      instructions = []
      programCounter = 0

      stepCount = 0
      breakPoint = nil

      start = 0
      current = 0

      totalCycleCount = 0
      resets = 0
      backtracks = 0
    }
  }
}
