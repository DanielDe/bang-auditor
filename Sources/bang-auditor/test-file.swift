import Foundation

func maybeReturn() -> Int? {
    return 4
}

func main() {
    print("this is a test file")

    let notOkay = maybeReturn()!

    let inlineCommentOkay = maybeReturn()! // bang-auditor:ignore

    // bang-auditor:disable
    let blockCommentOkay = maybeReturn()!
    let blockCommentAlsoOkay = maybeReturn()!
    // bang-auditor:enable

    let anotherNotOkay = maybeReturn()!

    let notOkayBool = true as! Bool
    print(notOkayBool)

    print(
      "All of them: \(notOkay), \(inlineCommentOkay), \(blockCommentOkay), \(blockCommentAlsoOkay), \(anotherNotOkay)"
    )
}
