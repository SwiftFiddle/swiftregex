import Foundation

@main
struct Main {
  static func main() {
    do {
      let pattern = CommandLine.arguments[1]
      let matchingOptions = CommandLine.arguments[2]
        .split(separator: ",", omittingEmptySubsequences: true)
        .map { String($0) }

      var parser = ExpressionParser(pattern: pattern, insensitive: matchingOptions.contains("i"))
      try parser.parse()

      let data = try JSONEncoder().encode(parser.tokens)
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
