import Foundation
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
                case .convertToPattern:
                    throw Abort(.notImplemented)
                case .match:
                    let pattern = request.pattern
                    let text = request.text
                    let matchOptions = request.matchOptions
                    let response = try match(pattern: pattern, text: text, matchOptions: matchOptions)

                    if let message = String(data: try encoder.encode(response), encoding: .utf8) {
                        ws.send(message)
                    }
                case .parseDSL:
                    let pattern = request.pattern
                    let response = try parseDSL(pattern: pattern)

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

    app.on(.POST, "api", "rest", "parseDSL", body: .collect(maxSize: "1mb")) { (req) -> ResultResponse in
        guard let request = try? req.content.decode(ExecRequest.self) else {
            throw Abort(.badRequest)
        }

        let pattern = request.pattern
        let response = try parseDSL(pattern: pattern)

        return response
    }

    func parseExpression(pattern: String, matchOptions: [String]) throws -> ResultResponse {
        let (stdout, stderr) = try exec(command: "ExpressionParser", arguments: pattern, matchOptions.joined(separator: ","))
        return ResultResponse(method: .parseExpression, result: stdout, error: stderr)
    }

    func convertToDSL(pattern: String, matchOptions: [String]) throws -> ResultResponse {
        let (stdout, stderr) = try exec(command: "DSLConverter", arguments: pattern, matchOptions.joined(separator: ","))
        return ResultResponse(method: .convertToDSL, result: stdout, error: stderr)
    }

    func match(pattern: String, text: String, matchOptions: [String]) throws -> ResultResponse {
        let (stdout, stderr) = try exec(command: "Matcher", arguments: pattern, text, matchOptions.joined(separator: ","))
        return ResultResponse(method: .match, result: stdout, error: stderr)
    }

    func parseDSL(pattern: String) throws -> ResultResponse {
        let (stdout, stderr) = try exec(command: "DSLParser", arguments: pattern)
        return ResultResponse(method: .parseDSL, result: stdout, error: stderr)
    }

    func exec(command: String, arguments: String...) throws -> (stdout: String, stderr: String) {
        let process = Process()
        let executableURL = URL(
            fileURLWithPath: "\(app.directory.workingDirectory).build/release/\(command)"
        )
        process.executableURL = executableURL
        process.arguments = arguments

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError

        try process.run()
        process.waitUntilExit()

        let stdoutData = standardOutput.fileHandleForReading.readDataToEndOfFile()
        guard let stdout = String(data: stdoutData, encoding: .utf8) else {
            throw Abort(.internalServerError)
        }

        let stderrData = standardError.fileHandleForReading.readDataToEndOfFile()
        guard let stderr = String(data: stderrData, encoding: .utf8) else {
            throw Abort(.internalServerError)
        }

        return (stdout, stderr)
    }
}
