import Vapor

func routes(_ app: Application) throws {
  app.get("health") { _ in ["status": "pass"] }
  app.get("healthz") { _ in ["status": "pass"] }

  app.get { (req) in req.view.render("index") }

  app.webSocket("api", "ws") { (req, ws) in
    ws.onBinary { (ws, buffer) in
      do {
        guard let data = buffer.getData(at: 0, length: buffer.readableBytes) else { return }

        let decoder = JSONDecoder()
        let request = try decoder.decode(ExecRequest.self, from: data)

        let encoder = JSONEncoder()

        switch request.method {
        case .parseExpression:
          let pattern = request.pattern
          let matchOptions = request.matchOptions
          let response = try parseExpression(pattern: pattern, matchOptions: matchOptions)

          if let message = String(data: try encoder.encode(response), encoding: .utf8) {
            ws.send(message)
          }
        case .convertToDSL:
          let pattern = request.pattern
          let matchOptions = request.matchOptions
          let response = try convertToDSL(pattern: pattern, matchOptions: matchOptions)

          if let message = String(data: try encoder.encode(response), encoding: .utf8) {
            ws.send(message)
          }
        case .match:
          let pattern = request.pattern
          let text = request.text
          let matchOptions = request.matchOptions
          let response = try match(pattern: pattern, text: text, matchOptions: matchOptions)

          if let message = String(data: try encoder.encode(response), encoding: .utf8) {
            ws.send(message)
          }
        case .debug:
          let pattern = request.pattern
          let text = request.text
          let matchOptions = request.matchOptions
          let step = request.step
          let response = try debug(pattern: pattern, text: text, matchOptions: matchOptions, step: step)

          if let message = String(data: try encoder.encode(response), encoding: .utf8) {
            ws.send(message)
          }
        }
      } catch {
        req.logger.error("\(error)")
      }
    }
  }

  app.on(.POST, "api", "rest", "parseExpression", body: .collect(maxSize: "1mb")) { (req) -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }

    let pattern = request.pattern
    let matchOptions = request.matchOptions
    let response = try parseExpression(pattern: pattern, matchOptions: matchOptions)

    return response
  }

  app.on(.POST, "api", "rest", "convertToDSL", body: .collect(maxSize: "1mb")) { (req) -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }

    let pattern = request.pattern
    let matchOptions = request.matchOptions
    let response = try convertToDSL(pattern: pattern, matchOptions: matchOptions)

    return response
  }

  app.on(.POST, "api", "rest", "match", body: .collect(maxSize: "1mb")) { (req) -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }

    let pattern = request.pattern
    let text = request.text
    let matchOptions = request.matchOptions
    let response = try match(pattern: pattern, text: text, matchOptions: matchOptions)

    return response
  }

  app.on(.POST, "api", "rest", "debug", body: .collect(maxSize: "1mb")) { (req) -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }

    let pattern = request.pattern
    let text = request.text
    let matchOptions = request.matchOptions
    let step = request.step

    let response = try debug(pattern: pattern, text: text, matchOptions: matchOptions, step: step)

    return response
  }

  func parseExpression(pattern: String, matchOptions: [String]) throws -> ResultResponse {
    do {
      let (stdout, stderr) = try exec(command: "ExpressionParser", timeout: 5, arguments: pattern, matchOptions.joined(separator: ","))
      return ResultResponse(method: .parseExpression, result: stdout, error: stderr)
    } catch is ProcessTimeoutError {
      return ResultResponse(method: .parseExpression, result: "", error: "Timed out")
    }
  }

  func convertToDSL(pattern: String, matchOptions: [String]) throws -> ResultResponse {
    do {
      let (stdout, stderr) = try exec(command: "DSLConverter", timeout: 5, arguments: pattern, matchOptions.joined(separator: ","))
      return ResultResponse(method: .convertToDSL, result: stdout, error: stderr)
    } catch is ProcessTimeoutError {
      return ResultResponse(method: .convertToDSL, result: "", error: "Timed out")
    }
  }

  func match(pattern: String, text: String, matchOptions: [String]) throws -> ResultResponse {
    do {
      let (stdout, stderr) = try exec(command: "Matcher", timeout: 5, arguments: pattern, text, matchOptions.joined(separator: ","))
      return ResultResponse(method: .match, result: stdout, error: stderr)
    } catch is ProcessTimeoutError {
      return ResultResponse(method: .match, result: "", error: "Timed out")
    }
  }

  func debug(pattern: String, text: String, matchOptions: [String], step: String?) throws -> ResultResponse {
    let context = Debugger.Context()

    func run(pattern: String, text: String, matchingOptions: [String] = [], until step: Int? = nil) throws {
      context.reset()
      context.breakPoint = step

      let debugger = Debugger()
      try debugger.run(pattern: pattern, text: text, matchingOptions: matchingOptions, context: context)
    }

    let breakPoint: Int?
    if let step {
      breakPoint = Int(step)
    } else {
      breakPoint = nil
    }
    try run(pattern: pattern, text: text, matchingOptions: matchOptions)
    let stepCount = context.stepCount

    try run(pattern: pattern, text: text, matchingOptions: matchOptions, until: breakPoint)

    let metrics = Debugger.Metrics(
      instructions: context.instructions,
      programCounter: context.programCounter,
      stepCount: stepCount,
      step: breakPoint ?? 1,
      totalCycleCount: context.totalCycleCount,
      resets: context.resets,
      backtracks: context.backtracks,
      traces: [
        Debugger.Trace(
          location: Debugger.Location(
            start: context.start,
            end: context.current
          )
        )
      ],
      failure: Debugger.Location(start: context.current, end: context.failurePosition),
    )
    let data = try JSONEncoder().encode(metrics)

    let result = String(data: data, encoding: .utf8) ?? ""
    let response = ResultResponse(method: .debug, result: result, error: "")

    return response
  }

  struct ProcessTimeoutError: Error {}

  func exec(command: String, timeout: TimeInterval = 5, arguments: String...) throws -> (stdout: String, stderr: String) {
    let process = Process()
    let executableURL = URL(
      fileURLWithPath: app.directory.workingDirectory
    )
    .appendingPathComponent(command)

    process.executableURL = executableURL
    process.arguments = arguments

    let standardOutput = Pipe()
    let standardError = Pipe()
    process.standardOutput = standardOutput
    process.standardError = standardError

    var stdoutData = Data()
    var stderrData = Data()
    let group = DispatchGroup()

    group.enter()
    standardOutput.fileHandleForReading.readabilityHandler = { handle in
      let chunk = handle.availableData
      if chunk.isEmpty {
        standardOutput.fileHandleForReading.readabilityHandler = nil
        group.leave()
      } else {
        stdoutData.append(chunk)
      }
    }

    group.enter()
    standardError.fileHandleForReading.readabilityHandler = { handle in
      let chunk = handle.availableData
      if chunk.isEmpty {
        standardError.fileHandleForReading.readabilityHandler = nil
        group.leave()
      } else {
        stderrData.append(chunk)
      }
    }

    try process.run()

    var didTimeout = false
    let timer = DispatchSource.makeTimerSource(queue: .global())
    timer.schedule(deadline: .now() + timeout)
    timer.setEventHandler {
      if process.isRunning {
        didTimeout = true
        process.terminate()
      }
    }
    timer.resume()

    group.wait()
    process.waitUntilExit()
    timer.cancel()

    if didTimeout {
      throw ProcessTimeoutError()
    }

    guard let stdout = String(data: stdoutData, encoding: .utf8) else {
      throw Abort(.internalServerError)
    }

    guard let stderr = String(data: stderrData, encoding: .utf8) else {
      throw Abort(.internalServerError)
    }

    return (stdout, stderr)
  }
}
