import Foundation

@main
struct Main {
    static func main() throws {
        do {
            let builder = CommandLine.arguments[1]
            let text = CommandLine.arguments[2]

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

            let regex = \#(builder)

            let text = """
            \#(text)
            """
            let matches = text.matches(of: regex)

            let results: [Match] = matches.map {
                let types = Mirror(reflecting: $0.output).children.map { type(of: $0.value) }
                var captures = [Group]()
                let outputs = Mirror(reflecting: $0).children.filter { $0.label == "anyRegexOutput" }.map { $0.value }
                for output in outputs {
                    let elements = Mirror(reflecting: output).children.filter { $0.label == "_elements" }.map { $0.value }
                    for element in elements {
                        let reps = Mirror(reflecting: element).children.map { $0.value }
                        for rep in reps {
                            let ranges = Mirror(reflecting: rep).children.filter { $0.label == "bounds" }.map { $0.value }
                            for (i, range) in ranges.enumerated() {
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
