import Foundation

@main
struct Main {
  static func main() throws {
    do {
      let pattern = CommandLine.arguments[1]
      let matchingOptions = CommandLine.arguments[2]
        .split(separator: ",", omittingEmptySubsequences: true)
        .map { String($0) }

      let converter = DSLConverter()
      let builderDSL = try converter.convert(pattern, matchingOptions: matchingOptions)

      let data = try JSONEncoder().encode(builderDSL)
      print(String(data: data, encoding: .utf8) ?? "")
    } catch {
      print("\(error)", to:&standardError)
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
