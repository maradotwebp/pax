import strutils, terminal, options
export strutils, terminal

template wrapIcon(content: string): string =
  ## wrap an icon in brackets
  "[" & content & "]"

const
  # icons
  debugIcon* = wrapIcon ":"
  infoIcon* = wrapIcon "-"
  warnIcon* = wrapIcon "!"
  errorIcon* = wrapIcon "x"
  rootIcon* = wrapIcon "Δ"
  # prefixes
  indentPrefix* = "└─"
  promptPrefix* = " └─ "

template echoDebug*(args: varargs[typed]): void =
  ## print a debug message.
  stdout.styledWrite(debugIcon, " ")
  stdout.styledWriteLine(args)

template echoInfo*(args: varargs[typed]): void =
  ## print an info message.
  stdout.styledWrite(fgGreen, infoIcon, resetStyle, " ")
  stdout.styledWriteLine(args)

template echoWarn*(args: varargs[typed]): void =
  ## print a warning message.
  stdout.styledWrite(fgYellow, warnIcon, resetStyle, " ")
  stdout.styledWriteLine(args)

template echoError*(args: varargs[typed]): void =
  ## Print an error message.
  stdout.styledWrite(fgRed, errorIcon, resetStyle, " ")
  stdout.styledWriteLine(args)

template echoRoot*(args: varargs[typed]): void =
  ## print a message prefixed with the root icon.
  stdout.styledWrite(fgMagenta, rootIcon, resetStyle, " ")
  stdout.styledWriteLine(args)

template echoIndent*(indent: Natural, args: varargs[typed]): void =
  ## print a message prefixed with the prompt symbols.
  stdout.styledWrite(" ".repeat(indent + 1), indentPrefix, " ")
  stdout.styledWriteLine(args)

template echoIndent*(args: varargs[typed]): void =
  ## print a message prefixed with the prompt symbols.
  stdout.styledWrite(" ", indentPrefix, " ")
  stdout.styledWriteLine(args)

proc toYN(choice: bool): string =
  if choice: "y" else: "n"

proc pretty[T](s: seq[T]): string =
  result = ""
  for i in s:
    result &= $i & ", "
  result.removeSuffix(", ")

proc prompt(prompt: string, default: Option[string]): string =
  ## prompt the user for input to an answer to a prompt.
  ## if default is specified & enter is pressed without an answer, default will be returned.
  while true:
    stdout.styledWrite(prompt)
    if default.isSome:
      stdout.styledWrite(" (default ", fgCyan, default.get(), resetStyle, ")")
    stdout.styledWrite(": ")
    let res = stdin.readLine()
    if not res.isEmptyOrWhitespace():
      return res
    elif default.isSome:
      return default.get()
    stdout.cursorUp()
    stdout.eraseLine()
    
proc promptYN(prompt: string, default: Option[bool]): bool =
  ## prompt the user for an answer to a yes/no question.
  ## if default is specified & enter is pressed without an answer, default will be returned.
  while true:
    stdout.styledWrite(prompt, " (", fgCyan, "y/n", resetStyle)
    if default.isSome:
      stdout.styledWrite(" - default ", fgCyan, toYN(default.get()), resetStyle)
    stdout.styledWrite("): ")
    let res = readLine(stdin)
    case res
      of "y", "Y": return true
      of "n", "N": return false
      of "":
        if default.isSome:
          return default.get()
    stdout.cursorUp()
    stdout.eraseLine()

proc promptChoice(prompt: string, choices: seq[char], format: string, default: Option[char]): char =
  ## prompt the user for a choice between multiple char values.
  while true:
    stdout.styledWrite(prompt, " (", fgCyan, format, resetStyle)
    if default.isSome:
      stdout.styledWrite(" - default ", fgCyan, $(default.get()), resetStyle)
    stdout.styledWrite("): ")
    let res = readLine(stdin)
    if res.isEmptyOrWhitespace() and default.isSome:
      return default.get()
    if res.len == 1 and res[0] in choices:
      return res[0]
    stdout.cursorUp()
    stdout.eraseLine()

proc promptChoice(prompt: string, choices: seq[int], format: string, default: Option[int]): int =
  ## prompt the user for a choice between multiple int values.
  while true:
    stdout.styledWrite(prompt, " (", fgCyan, format, resetStyle)
    if default.isSome:
      stdout.styledWrite(" - default ", fgCyan, $(default.get()), resetStyle)
    stdout.styledWrite("): ")
    let res = readLine(stdin)
    if res.isEmptyOrWhitespace() and default.isSome:
      return default.get()
    try:
      if res.parseInt in choices:
        return res.parseInt
    except:
      discard
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