import Foundation
import RegexBuilder
@testable import _RegexParser
@testable @_spi(RegexBuilder) import _StringProcessing

struct PatternConverter {
    func convert(_ root: DSLTree.Node) throws -> String {
        emitRoot(root)
        return ""
    }

    func emitRoot(_ root: DSLTree.Node) {
        for node in root.children {
            emitNode(node)
        }
    }

    func emitNode(_ node: DSLTree.Node) {
        switch node {
        case .orderedChoice(let choice):
            print("orderedChoice")
            for node in choice {
                emitNode(node)
            }
        case .concatenation(let concatenation):
            print("concatenation")
            for node in concatenation {
                emitNode(node)
            }
        case .capture(name: let name, reference: let reference, let node, let transform):
            print("capture")
            emitNode(node)
        case .nonCapturingGroup(let kind, let node):
            print("nonCapturingGroup")
            emitNode(node)
        case .conditional(let kind, let thenNode, let elseNode):
            print("conditional")
            emitNode(thenNode)
            emitNode(elseNode)
        case .quantification(let amount, let kind, let node):
            print("quantification")
            
            emitNode(node)
        case .customCharacterClass(_):
            print("customCharacterClass")
        case .atom(_):
            print("atom")
        case .trivia(_):
            print("trivia")
        case .empty:
            print("empty")
        case .quotedLiteral(_):
            print("quotedLiteral")
        case .regexLiteral(_):
            print("regexLiteral")
        case .absentFunction(_):
            print("absentFunction")
        case .convertedRegexLiteral(let node, _):
            print("convertedRegexLiteral")
            emitNode(node)
        case .consumer(_):
            print("consumer")
        case .matcher(_, _):
            print("matcher")
        case .characterPredicate(_):
            print("characterPredicate")
        }
    }
}
