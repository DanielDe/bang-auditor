# bang-auditor

Identifies and prints out all uses of `!` in your Swift codebase.

Options to ignore specific lines or entire blocks.

## Example

```swift
// test-file.swift
func main() {
    let notOkay = maybeSomething()!

    let inlineOkay = maybeSomething()! // bang-auditor:ignore

    // bang-auditor:disable
    let blockOkay = maybeSomething()!
    let anotherBlockOkay = maybeSomething() as! User
    // bang-auditor:enable

    let anotherNotOkay = maybeSomething() as! Employee
}
```

```
⌘ bang-auditor ./test-file.swift
./test-file.swift
    line 3
        let notOkay = maybeSomething()!
    line 12
        let anotherNotOkay = maybeSomething() as! Employee
```

## Usage

Accepts one or more file or directory paths.
If a directory path is specified, `bang-auditor` runs on all `.swift` files it finds in that directory.

## Ignore and disable

To ignore bangs on a single line, add a `// bang-auditor:ignore` comment to the end of the line:

```swift
let inlineOkay = maybeSomething()! // bang-auditor:ignore
```

To ignore bangs on multiple lines, surround those lines with a pair of `// bang-auditor:disable` and `// bang-auditor:enable` comments:

```swift
// bang-auditor:disable
let blockOkay = maybeSomething()!
let anotherBlockOkay = maybeSomething() as! User
// bang-auditor:enable
```
