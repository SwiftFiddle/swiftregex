import Foundation

@main
struct Main {
  static func main() {
    do {
      let pattern = CommandLine.arguments[1]
      let matchingOptions = CommandLine.arguments[2]
        .split(separator: ",", omittingEmptySubsequences: true)
        .map { String($0) }

      var parser = ExpressionParser(pattern: pattern, matchingOptions: matchingOptions)
      parser.parse()

      let encoder = JSONEncoder()
      let data = try encoder.encode(parser.tokens)
      print(String(data: data, encoding: .utf8) ?? "")

      if let diagnostics = parser.diagnostics {
        let errors = diagnostics.diags.map {
          let location = $0.location
          let (start, end) = (location.start, location.end)

          let behavior = switch $0.behavior {
          case .fatalError:
            "Fatal Error"
          case .error:
            "Error"
          case .warning:
            "Warning"
          }
          return LocatedMessage(
            behavior: behavior,
            message: $0.message,
            location: Location(
              start: start.utf16Offset(in: pattern), end: end.utf16Offset(in: pattern)
            )
          )
        }

        let data = try JSONEncoder().encode(errors)
        print(String(data: data, encoding: .utf8) ?? "", to: &standardError)
      }
    } catch {
      print("\(error)", to: &standardError)
    }
  }
}

var standardError = FileHandle.standardError

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    self.write(data)
  }
}

struct LocatedMessage: Codable {
  let behavior: String
  let message: String
  let location: Location
}
