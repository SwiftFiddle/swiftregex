import Foundation
import RegexBuilder
@testable @_spi(RegexBuilder) import _StringProcessing

@main
struct Main {
    static func main() throws {
        do {
//            let builderDSL = CommandLine.arguments[1]

            let regex = Regex {
                Optionally {
                    Capture {
                        Regex {
                            Capture {
                                Repeat(count: 3) {
                                    One(.digit)
                                }
                            }
                            ChoiceOf {
                                "."
                                "-"
                            }
                        }
                    }
                }
                Capture {
                    Repeat(count: 3) {
                        One(.digit)
                    }
                }
                ChoiceOf {
                    "."
                    "-"
                }
                Capture {
                    Repeat(count: 4) {
                        One(.digit)
                    }
                }
            }
            let converter = PatternConverter()
            let pattern = try converter.convert(regex.root)

            let data = try JSONEncoder().encode(pattern)
            print(String(data: data, encoding: .utf8) ?? "")
        } catch {
            print("\(error)", to:&standardError)
        }
    }
}

var standardError = FileHandle.standardError

extension FileHandle : TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}
