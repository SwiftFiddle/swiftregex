import Foundation

struct ExecRequest: Codable {
  let method: RequestMethod
  let pattern: String
  let text: String
  let matchOptions: [String]
  let step: String?
}

enum RequestMethod: String, Codable {
  case parseExpression
  case convertToDSL
  case match
  case debug
}
