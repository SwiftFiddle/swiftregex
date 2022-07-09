import Foundation
//import SwiftSyntax
//import SwiftSyntaxParser

@main
struct Main {
    static func main() throws {
        do {
            let builder = CommandLine.arguments[1]
            let text = CommandLine.arguments[2]

            let regexVarName = "regex_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
            let code = "let \(regexVarName) = \(builder)"
//            var code = ""
//            let sourceFile = try SyntaxParser.parse(source: builder)
//            for statement in sourceFile.statements {
//                let syntaxes = statement.children.map { $0 }
//                if !syntaxes.isEmpty {
//                    if let _ = syntaxes[0].as(FunctionCallExprSyntax.self) {
//                        code += """
//
//                            let \(regexVarName) = \(statement)
//                            """
//                        break
//                    } else if let variableDecl = syntaxes[0].as(VariableDeclSyntax.self) {
//                        let bindings = variableDecl.bindings.map { $0 }
//                        if let pattern = bindings[0].pattern.as(IdentifierPatternSyntax.self) {
//                            if let initializer = bindings[0].initializer {
//                                if let functionCallExpr = initializer.value.as(FunctionCallExprSyntax.self) {
//                                    if let calledExpression = functionCallExpr.calledExpression.as(IdentifierExprSyntax.self) {
//                                        if calledExpression.identifier.text == "Regex" {
//                                            code += """
//                                                \(statement)
//
//                                                let \(regexVarName) = \(pattern.identifier.text)
//                                                """
//                                            break
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//
//                code += """
//
//                    \(statement)
//                    """
//            }

            let script = #"""
            import Foundation
            import RegexBuilder
            import _StringProcessing

            struct Match: Codable {
              let location: Location
              let value: String
              let captures: [Group]
            }

            struct Group: Codable {
              let location: Location?
              let value: String?
              let type: String
            }

            struct Location: Codable {
              let start: Int
              let end: Int
            }

            \#(code)

            let text = """
            \#(text)
            """

            let matches = text.matches(of: \#(regexVarName))

            let results: [Match] = matches.map {
              let types = Mirror(reflecting: $0.output).children.map { type(of: $0.value) }
              var captures = [Group]()
              let outputs = Mirror(reflecting: $0).children.filter { $0.label == "anyRegexOutput" }.map { $0.value }
              for output in outputs {
                let elements = Mirror(reflecting: output).children.filter { $0.label == "_elements" }.map { $0.value }
                for element in elements {
                  let reps = Mirror(reflecting: element).children.map { $0.value }
                  for rep in reps {
                    let contents = Mirror(reflecting: rep).children.filter { $0.label == "content" }.map { $0.value }
                    for content in contents {
                    let optionalRanges = Mirror(reflecting: content).children.filter { $0.label == "some" }.map { $0.value }
                      for optionalRange in optionalRanges {
                        let ranges = Mirror(reflecting: optionalRange).children.filter { $0.label == "range" }.map { $0.value }
                        for (i, range) in ranges.dropFirst().enumerated() {
                          if let range = range as? Range<String.Index> {
                            captures.append(
                              Group(
                                location: Location(
                                  start: range.lowerBound.utf16Offset(in: text),
                                  end: range.upperBound.utf16Offset(in: text)
                                ),
                                value: String(text[range]),
                                type: String(reflecting: types[i])
                              )
                            )
                          } else {
                            captures.append(
                              Group(
                                location: nil,
                                value: nil,
                                type: "Unknown"
                              )
                            )
                          }
                        }
                      }
                    }
                  }
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

            let data = try JSONEncoder().encode(results)
            print(String(data: data, encoding: .utf8) ?? "")
            """#

            let standardInput = Pipe()
            let standardOutput = Pipe()
            let standardError = Pipe()

            let fileHandle = standardInput.fileHandleForWriting
            fileHandle.write(script)
            try fileHandle.close()

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
            process.arguments = ["-Xfrontend", "-enable-experimental-string-processing", "-enable-bare-slash-regex", "-"]

            process.standardInput = standardInput
            process.standardOutput = standardOutput
            process.standardError = standardError

            try process.run()
            process.waitUntilExit()

            let stdoutData = standardOutput.fileHandleForReading.readDataToEndOfFile()
            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            print(stdout)

            let stderrData = standardError.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            print(stderr, to:&IO.standardError)
        } catch {
            print("\(error)", to:&IO.standardError)
        }
    }
}

struct IO {
    static var standardError = FileHandle.standardError;
}

extension FileHandle : TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}
