import Foundation
import SwiftSyntax

fileprivate extension Trivia {
    var containsNewline: Bool {
        self.contains { piece in
            switch piece {
            case .newlines:
                return true
            default:
                return false
            }
        }
    }

    var numNewLines: Int {
        self.map { piece in
            switch piece {
            case .newlines(let numNewlines):
                return numNewlines
            default:
                return 0
            }
        }.reduce(0, +)
    }

    var whitespaceText: String {
        self.map { piece in
            switch piece {
            case .spaces(let numSpaces):
                return String(repeating: " ", count: numSpaces)
            case .tabs(let numTabs):
                return String(repeating: "\t", count: numTabs)
            default:
                return ""
            }
        }.joined(separator: "")
    }

    var firstComment: String {
        guard let firstPiece = self.first else {
            return ""
        }

        switch firstPiece {
        case .lineComment(let comment):
            return comment
        case .blockComment(let comment):
            return comment
        case .docLineComment(let comment):
            return comment
        case .docBlockComment(let comment):
            return comment
        default:
            return ""
        }
    }

    var containsDisableComment: Bool {
        self.contains { piece in
            switch piece {
            case .lineComment(let comment), .blockComment(let comment),
                 .docLineComment(let comment), .docBlockComment(let comment):
                let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
                let commentText = trimmed.suffix(trimmed.count - 2).trimmingCharacters(in: .whitespacesAndNewlines)

                return commentText == "bang-auditor:disable"
            default:
                return false
            }
        }
    }

    var containsEnableComment: Bool {
        self.contains { piece in
            switch piece {
            case .lineComment(let comment), .blockComment(let comment),
                 .docLineComment(let comment), .docBlockComment(let comment):
                let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
                let commentText = trimmed.suffix(trimmed.count - 2).trimmingCharacters(in: .whitespacesAndNewlines)

                return commentText == "bang-auditor:enable"
            default:
                return false
            }
        }
    }
}

class BangAuditorVisitor: SyntaxRewriter {
    let filePath: String

    var isDisabled = false
    var currentLineNumber = 1
    var currentLine = ""
    var currentLineContainsBang = false

    init(filePath: String) {
        self.filePath = filePath
    }

    static func commentDisablesLine(_ comment: String) -> Bool {
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let commentText = trimmed.suffix(trimmed.count - 2).trimmingCharacters(in: .whitespacesAndNewlines)

        return commentText == "bang-auditor:ignore"
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
        if token.leadingTrivia.containsDisableComment {
            self.isDisabled = true
        }

        if token.leadingTrivia.containsNewline {
            if self.currentLineContainsBang && !self.isDisabled {
                let firstComment = token.leadingTrivia.firstComment

                if firstComment.isEmpty || !BangAuditorVisitor.commentDisablesLine(firstComment) {
                    // TODO: print the line by reading the file and grabbing the correct line, instead of reconstructing it.
                    print("\(self.filePath)::\(self.currentLineNumber)")
                    print("\n    \(self.currentLine.trimmingCharacters(in: .whitespacesAndNewlines)) \(token.leadingTrivia.firstComment)\n")
                }
            }

            self.currentLineContainsBang = false
            self.currentLine = ""
        }

        if token.leadingTrivia.containsEnableComment {
            self.isDisabled = false
        }

        self.currentLine += token.text + token.trailingTrivia.whitespaceText

        currentLineNumber += token.leadingTrivia.numNewLines

        if token.tokenKind == .exclamationMark {
            self.currentLineContainsBang = true
        }

        currentLineNumber += token.trailingTrivia.numNewLines

        return token
    }
}

print("")
let filePath = "./Sources/bang-auditor/test-file.swift"
let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: filePath))
let _ = BangAuditorVisitor(filePath: filePath).visit(sourceFile)
