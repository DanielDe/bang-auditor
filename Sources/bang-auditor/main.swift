import Foundation
import SwiftSyntax
import Rainbow

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
    var isDisabled = false
    var currentLineNumber = 1
    var currentLineContainsBang = false

    var detectedLineNumbers: [Int] = []

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
                    self.detectedLineNumbers.append(self.currentLineNumber)
                }
            }

            self.currentLineContainsBang = false
        }

        if token.leadingTrivia.containsEnableComment {
            self.isDisabled = false
        }

        currentLineNumber += token.leadingTrivia.numNewLines

        if token.tokenKind == .exclamationMark {
            self.currentLineContainsBang = true
        }

        return token
    }
}

func isDirectory(path: String) -> Bool {
    try! URL(fileURLWithPath: filePaths.first!).resourceValues(forKeys: [.isDirectoryKey]).isDirectory!
}

func normalizeDirectoryPath(_ path: String) -> String {
    guard path.hasSuffix("/") else {
        return path
    }

    return String(path.dropLast(1))
}

let filePaths = Array(CommandLine.arguments.dropFirst())
guard !filePaths.isEmpty else {
    print("You must specify at least one path")
    exit(1)
}

filePaths.forEach { filePath in
    var swiftFilePaths: [String] = []

    if isDirectory(path: filePath) {
        let normalizedPath = normalizeDirectoryPath(filePath)
        if let enumerator = FileManager.default.enumerator(atPath: normalizedPath) {
            for case let path as String in enumerator {
                if path.hasSuffix(".swift") {
                    swiftFilePaths.append("\(normalizedPath)/\(path)")
                }
            }
        }
    } else {
        swiftFilePaths.append(filePath)
    }

    swiftFilePaths.forEach { swiftFilePath in
        let sourceFile = try! SyntaxParser.parse(URL(fileURLWithPath: swiftFilePath))
        let bangVisitor = BangAuditorVisitor()
        let _ = bangVisitor.visit(sourceFile)

        let fileContents = try! String(contentsOf: URL(fileURLWithPath: swiftFilePath)) // bang-auditor:ignore
        let fileLines = fileContents.split(separator: "\n", omittingEmptySubsequences: false)

        if !bangVisitor.detectedLineNumbers.isEmpty {
            print("\(swiftFilePath)".bold)
            bangVisitor.detectedLineNumbers.forEach { lineNumber in
                print("    line \(lineNumber)".red)
                print("        \(fileLines[lineNumber - 1].trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
    }
}
