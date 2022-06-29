import Foundation

struct ExecRequest: Codable {
    let method: RequestMethod
    let pattern: String
    let text: String
    let matchOptions: [String]
}

enum RequestMethod: String, Codable {
    case parseExpression
    case convertToDSL
    case convertToPattern
    case match
    case parseDSL
    case testBuilder
}
