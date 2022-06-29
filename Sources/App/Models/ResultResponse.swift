import Foundation
import Vapor

struct ResultResponse: Content {
    let method: RequestMethod
    let result: String
    let error: String
}
