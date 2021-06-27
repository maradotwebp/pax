import strutils, clr, terminal

var
  ## if true, all promptYN will be skipped and return true.
  skipYNSetting*: bool = false


proc pretty[T](s: seq[T]): string =
  ## pretty-print a sequence
  result = ""
  for i in s:
    result &= $i & ", "
  result.removeSuffix(", ")

proc prompt*(prompt: string, choices: seq[string] = newSeq[string](), choiceFormat: string = choices.pretty, default: string = ""): string =
  ## prompt the user for input to an answer to the `prompt`
  ## if `default` is specified & enter is pressed without input, `default` will be returned.
  let hasChoiceFormat = choiceFormat != ""
  let hasDefault = default != ""
  while true:
    clrWrite(prompt)
    if hasChoiceFormat or hasDefault:
      clrWrite(" (")
    if choiceFormat != "":
      clrWrite(choiceFormat.cyanFg)
    if hasChoiceFormat and hasDefault:
      clrWrite(" - ")
    if hasDefault:
      clrWrite("default ", default.cyanFg)
    if hasChoiceFormat or hasDefault:
      clrWrite(")")
    clrWrite(": ")
    let res = stdin.readLine()
    if res.isEmptyOrWhitespace():
      if hasDefault:
        return default
    elif len(choices) > 0:
      if res in choices:
        return res
    else:
      return res
    stdout.cursorUp()
    stdout.eraseLine()

converter toYN(choice: bool): string =
  ## convert a bool to a y/n char
  if choice: "y" else: "n"

converter fromYN(choice: string): bool =
  ## convert a y/n char to a bool
  case choice:
    of "y", "Y": return true
    of "n", "N": return false
    else: raise newException(ValueError, "could not parse y/n")

proc promptYN*(prompt: string, default: bool): bool =
  ## prompt the user for an answer to a yes/no question.
  if skipYNSetting: return true
  let answer = prompt(prompt, choices = @["y", "Y", "n", "N"], choiceFormat = "y/n", default = $toYn(default))
  return fromYN(answer)
