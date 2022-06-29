import Foundation
import _RegexParser

@main
struct Main {
    static func main() throws {
        do {
            let pattern = CommandLine.arguments[1]
            let text = CommandLine.arguments[2]
            let matchingOptions = CommandLine.arguments[3]
                .split(separator: ",", omittingEmptySubsequences: true)
                .map { String($0) }

            do {
                _ = try _RegexParser.parse(pattern, .syntactic, .traditional)
            } catch {
                return
            }

            let matches = try Matcher.match(pattern: pattern, text: text, matchingOptions: matchingOptions)

            let data = try JSONEncoder().encode(matches)
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
