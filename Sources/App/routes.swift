import Vapor

func routes(_ app: Application) throws {
  app.get("health") { _ in ["status": "pass"] }
  app.get("healthz") { _ in ["status": "pass"] }

  app.get { (req) in req.view.render("index") }

  app.webSocket("api", "ws") { (req, ws) in
    ws.onBinary { (ws, buffer) in
      guard let data = buffer.getData(at: 0, length: buffer.readableBytes) else { return }
      Task {
        do {

          let decoder = JSONDecoder()
          let request = try decoder.decode(ExecRequest.self, from: data)

          let encoder = JSONEncoder()
          let response: ResultResponse

          switch request.method {
          case .parseExpression:
            response = try await parseExpression(pattern: request.pattern, matchOptions: request.matchOptions, id: request.id)
          case .convertToDSL:
            response = try await convertToDSL(pattern: request.pattern, matchOptions: request.matchOptions, id: request.id)
          case .match:
            response = try await match(pattern: request.pattern, text: request.text, matchOptions: request.matchOptions, id: request.id)
          case .debug:
            response = try await debug(pattern: request.pattern, text: request.text, matchOptions: request.matchOptions, step: request.step, id: request.id)
          }

          let message = String(data: try encoder.encode(response), encoding: .utf8)!
          try await ws.send(message)
        } catch {
          req.logger.error("\(error)")
        }
      }
    }
  }

  app.on(.POST, "api", "rest", "parseExpression", body: .collect(maxSize: "1mb")) { (req) async throws -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }
    return try await parseExpression(pattern: request.pattern, matchOptions: request.matchOptions, id: request.id)
  }

  app.on(.POST, "api", "rest", "convertToDSL", body: .collect(maxSize: "1mb")) { (req) async throws -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }
    return try await convertToDSL(pattern: request.pattern, matchOptions: request.matchOptions, id: request.id)
  }

  app.on(.POST, "api", "rest", "match", body: .collect(maxSize: "1mb")) { (req) async throws -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }
    return try await match(pattern: request.pattern, text: request.text, matchOptions: request.matchOptions, id: request.id)
  }

  app.on(.POST, "api", "rest", "debug", body: .collect(maxSize: "1mb")) { (req) async throws -> ResultResponse in
    guard let request = try? req.content.decode(ExecRequest.self) else {
      throw Abort(.badRequest)
    }
    return try await debug(pattern: request.pattern, text: request.text, matchOptions: request.matchOptions, step: request.step, id: request.id)
  }

  func parseExpression(pattern: String, matchOptions: [String], id: String?) async throws -> ResultResponse {
    do {
      let (stdout, stderr) = try await exec(command: "ExpressionParser", timeout: 5, arguments: pattern, matchOptions.joined(separator: ","))
      return ResultResponse(method: .parseExpression, result: stdout, error: stderr, id: id)
    } catch is ProcessTimeoutError {
      return ResultResponse(method: .parseExpression, result: "", error: "Timed out", id: id)
    }
  }

  func convertToDSL(pattern: String, matchOptions: [String], id: String?) async throws -> ResultResponse {
    do {
      let (stdout, stderr) = try await exec(command: "DSLConverter", timeout: 5, arguments: pattern, matchOptions.joined(separator: ","))
      return ResultResponse(method: .convertToDSL, result: stdout, error: stderr, id: id)
    } catch is ProcessTimeoutError {
      return ResultResponse(method: .convertToDSL, result: "", error: "Timed out", id: id)
    }
  }

  func match(pattern: String, text: String, matchOptions: [String], id: String?) async throws -> ResultResponse {
    do {
      let (stdout, stderr) = try await exec(command: "Matcher", timeout: 5, arguments: pattern, text, matchOptions.joined(separator: ","))
      return ResultResponse(method: .match, result: stdout, error: stderr, id: id)
    } catch is ProcessTimeoutError {
      return ResultResponse(method: .match, result: "", error: "Timed out", id: id)
    }
  }

  func debug(pattern: String, text: String, matchOptions: [String], step: String?, id: String?) async throws -> ResultResponse {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global().async {
        do {
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
          let response = ResultResponse(method: .debug, result: result, error: "", id: id)

          continuation.resume(returning: response)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  struct ProcessTimeoutError: Error {}

  func exec(command: String, timeout: TimeInterval = 5, arguments: String...) async throws -> (stdout: String, stderr: String) {
    try await withCheckedThrowingContinuation { continuation in
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

      let syncQueue = DispatchQueue(label: "exec-sync")
      var didTimeout = false
      group.enter()
      process.terminationHandler = { _ in
        group.leave()
      }

      do {
        try process.run()
      } catch {
        standardOutput.fileHandleForReading.readabilityHandler = nil
        standardError.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
        continuation.resume(throwing: error)
        return
      }

      let timer = DispatchSource.makeTimerSource(queue: syncQueue)
      timer.schedule(deadline: .now() + timeout)
      timer.setEventHandler {
        if process.isRunning {
          didTimeout = true
          process.terminate()
          let pid = process.processIdentifier
          syncQueue.asyncAfter(deadline: .now() + 1) {
            if process.isRunning {
              kill(pid, SIGKILL)
            }
          }
        }
      }
      timer.resume()

      group.notify(queue: syncQueue) {
        timer.cancel()

        if didTimeout {
          continuation.resume(throwing: ProcessTimeoutError())
          return
        }

        guard let stdout = String(data: stdoutData, encoding: .utf8),
              let stderr = String(data: stderrData, encoding: .utf8) else {
          continuation.resume(throwing: Abort(.internalServerError))
          return
        }

        continuation.resume(returning: (stdout, stderr))
      }
    }
  }
}
