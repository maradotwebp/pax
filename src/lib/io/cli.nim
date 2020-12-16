import strutils, terminal, typetraits, options
import term

proc promptDefault*(default: Option[string], prefix: string = " - default ", suffix: string = ""): string =
    if default.isSome: prefix & default.get().clrCyan & suffix
    else: ""

proc toYN(choice: bool): string =
    if choice: "y" else: "n"

proc pretty[T](s: seq[T]): string =
    result = ""
    for i in s:
        result &= $i & ", "
    result.removeSuffix(", ")

proc isInt(s: string): bool =
    try:
        discard s.parseInt()
        return true
    except ValueError:
        return false

proc toStr[T](s: T): string = $s

proc prompt(prompt: string, default: Option[string]): string =
    ## Prompt the user for input to an answer to a prompt.
    ## If default is specified & enter is pressed without an answer, default will be returned.
    while true:
        stdout.write prompt, promptDefault(default, prefix=" (default ", suffix=")"), ": "
        let res = readLine(stdin)
        if not res.isEmptyOrWhitespace():
            return res
        elif default.isSome:
            return default.get()
        stdout.cursorUp()
        stdout.eraseLine()

proc promptYN(prompt: string, default: Option[bool]): bool =
    ## Prompt the user for an answer to a yes/no question.
    ## If default is specified & enter is pressed without an answer, default will be returned.
    let hasDefault = default.isSome
    let def = default.get()
    while true:
        stdout.write prompt, " ", "(", "y/n".clrCyan, promptDefault(default.map(toYN)), "): "
        let res = readLine(stdin)
        case res
            of "y", "Y": return true
            of "n", "N": return false
            of "":
                if hasDefault: return def
        stdout.cursorUp()
        stdout.eraseLine()

proc promptChoice(prompt: string, choices: seq[char], format: string, default: Option[char]): char =
    ## Prompt the user for a choice between multiple char values.
    while true:
        stdout.write prompt, " ", "(", format.clrCyan, promptDefault(default.map(toStr)), "): "
        let res = readLine(stdin)
        if res.isEmptyOrWhitespace() and default.isSome:
            return default.get()
        if res.len == 1 and res[0] in choices:
            return res[0]
        stdout.cursorUp()
        stdout.eraseLine()

proc promptChoice(prompt: string, choices: seq[int], format: string, default: Option[int]): int =
    ## Prompt the user for a choice between multiple int values.
    while true:
        stdout.write prompt, " ", "(", format.clrCyan, promptDefault(default.map(toStr)), "): "
        let res = readLine(stdin)
        if res.isEmptyOrWhitespace() and default.isSome:
            return default.get()
        if res.isInt and res.parseInt in choices:
            return res.parseInt
        stdout.cursorUp()
        stdout.eraseLine()

proc prompt*(prompt: string, default: string): string = prompt(prompt, some(default))
proc prompt*(prompt: string): string = prompt(prompt, none[string]())

proc promptYN*(prompt: string, default: bool): bool = promptYN(prompt, some(default))
proc promptYN*(prompt: string): bool = promptYN(prompt, none[bool]())

proc promptChoice*(prompt: string, choices: seq[char], format: string, default: char): char = promptChoice(prompt, choices, format, some(default))
proc promptChoice*(prompt: string, choices: seq[char], format: string): char = promptChoice(prompt, choices, format, none[char]())
proc promptChoice*(prompt: string, choices: seq[char], default: char): char = promptChoice(prompt, choices, choices.pretty, some(default))
proc promptChoice*(prompt: string, choices: seq[char]): char = promptChoice(prompt, choices, choices.pretty, none[char]())
proc promptChoice*(prompt: string, choices: seq[int], format: string, default: int): int = promptChoice(prompt, choices, format, some(default))
proc promptChoice*(prompt: string, choices: seq[int], format: string): int = promptChoice(prompt, choices, format, none[int]())
proc promptChoice*(prompt: string, choices: seq[int], default: int): int = promptChoice(prompt, choices, choices.pretty, some(default))
proc promptChoice*(prompt: string, choices: seq[int]): int = promptChoice(prompt, choices, choices.pretty, none[int]())
