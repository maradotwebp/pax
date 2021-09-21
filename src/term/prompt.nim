## Module for prompting the user for input - in a pretty way.
## 
## Pax needs to prompt the user multiple times for stuff like the modpack name,
## modloader type, and so on.
## 
## Three different prompt types are implemented:
## - Outputting a question and excepting a string answer.
## - Outputting a question and expecting a selected singular choice out of multiple choices.
## - Outputting a yes/no question and expecting a yes/no answer.

import strutils, terminal
import color

var
  ## if true, all promptYN will be skipped and return true.
  skipYNSetting*: bool = false

proc pretty[T](s: seq[T]): string =
  ## pretty-print a sequence
  result = ""
  for i in s:
    result &= $i & ", "
  result.removeSuffix(", ")

proc prompt*(
  prompt: string,
  choices: seq[string] = newSeq[string](),
  choiceFormat: string = choices.pretty,
  default: string = ""
): string =
  ## prompts the user for input to the given question `prompt`.
  ## 
  ## The prompt will be displayed in four different ways depending on the parameters:
  ## - `<prompt> (<choiceFormat> - default <default>): ` if `choices` (optionally `choiceFormat`) & `default` is defined
  ## - `<prompt> (<choiceFormat>): ` if `choices` is defined
  ## - `<prompt> (default <default>): ` if `default` is defined
  ## - `<prompt>: ` otherwise
  ## 
  ## if `choices` is defined, only inputs present in `choices` will be accepted as input.
  ## if `default` is specified, skipping the question by pressing enter without input will return default.
  let hasChoiceFormat = choiceFormat != ""
  let hasDefault = default != ""
  while true:
    # Output question
    stdout.clrWrite(prompt)
    if hasChoiceFormat or hasDefault:
      stdout.clrWrite(" (")
    if choiceFormat != "":
      stdout.clrWrite(choiceFormat.fgCyan)
    if hasChoiceFormat and hasDefault:
      stdout.clrWrite(" - ")
    if hasDefault:
      stdout.clrWrite("default ", default.fgCyan)
    if hasChoiceFormat or hasDefault:
      stdout.clrWrite(")")
    stdout.clrWrite(": ")
    # Retrieve answer
    let res = stdin.readLine()
    if res.isEmptyOrWhitespace():
      if hasDefault:
        return default
    elif choices.len > 0:
      if res in choices:
        return res
    else:
      return res
    # Gives an error on windows
    when not defined(testing):
      stdout.cursorUp()
      stdout.eraseLine()

converter toYN(choice: bool): string =
  ## convert a bool to a y/n char.
  if choice: "y" else: "n"

converter fromYN(choice: string): bool =
  ## convert a y/n char to a bool.
  case choice:
    of "y", "Y": return true
    of "n", "N": return false
    else: raise newException(ValueError, "could not parse y/n")

proc promptYN*(prompt: string, default: bool): bool =
  ## prompt the user for an answer to a yes/no question.
  ## if `default` is specified, skipping the question by pressing enter without input will return default.
  if skipYNSetting: return true
  let answer = prompt(prompt, choices = @["y", "Y", "n", "N"], choiceFormat = "y/n", default = default.toYN.`$`)
  return answer.fromYN
