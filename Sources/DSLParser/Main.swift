import Foundation

@main
struct Main {
    static func main() throws {
        do {
            let pattern = CommandLine.arguments[1]

            let parser = DSLParser()
            let tokens = try parser.parse(pattern)

            let data = try JSONEncoder().encode(tokens)
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
