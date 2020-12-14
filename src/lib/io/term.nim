import macros

template clrRed*(text: string): string = "\e[31m" & text & "\e[0m"
template clrGreen*(text: string): string = "\e[32m" & text & "\e[0m"
template clrYellow*(text: string): string = "\e[33m" & text & "\e[0m"
template clrBlue*(text: string): string = "\e[34m" & text & "\e[0m"
template clrMagenta*(text: string): string = "\e[35m" & text & "\e[0m"
template clrCyan*(text: string): string = "\e[36m" & text & "\e[0m"
template clrGray*(text: string): string = "\e[90m" & text & "\e[0m"

template debugIcon*(): string = "[" & ":".clrGray & "]"
template infoIcon*(): string = "[-]"
template warnIcon*(): string = "[" & "!".clrYellow & "]"
template errorIcon*(): string = "[" & "X".clrRed & "]"

macro unpackArgsWithPrefix(callee: untyped; pre: string; args: varargs[untyped]): untyped =
  ## like macros.unpackVarargs, but with a prefix
  result = newCall(callee)
  result.add pre
  for i in 0 ..< args.len:
    result.add args[i]

template echoDebug*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, debugIcon() & " ", args)
template echoInfo*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, infoIcon() & " ", args)
template echoWarn*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, warnIcon() & " ", args)
template echoError*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, errorIcon() & " ", args)

proc readInput*(text: string, prefix = " └─ "): string =
  ## Ask the user for input.
  while true:
    stdout.write prefix, text, ": "
    result = readLine(stdin)
    case result:
      of "": discard
      else: break

proc readInput*(text: string, default: string, prefix = " └─ "): string =
  ## Ask the user for input.
  ## Will default to the default parameter if nothing is entered.
  stdout.write prefix, text, " (default: ", default.clrCyan, "): "
  var input: string = readLine(stdin)
  result = if input != "": input else: default

proc readYesNo*(text: string, prefix = " └─ "): bool =
  ## Ask the user a yes/no question.
  while true:
    stdout.write prefix, text, " (", "y/n".clrCyan, "): "
    case readLine(stdin):
      of "y", "Y", "Yes", "yes", "YES": return true
      of "n", "N", "No", "no", "NO": return false
      else: discard

proc readYesNo*(text: string, default: char, prefix = " └─ "): bool =
  ## Ask the user a yes/no question.
  ## Will default to the default parameter if nothing is entered.
  while true:
    stdout.write prefix, text, " (", "y/n".clrCyan, " - default: ", ($default).clrCyan, "): "
    case readLine(stdin):
      of "y", "Y", "Yes", "yes", "YES": return true
      of "n", "N", "No", "no", "NO": return false
      of "":
        case default:
          of 'y': return true
          of 'n': return false
          else: assert(false)
      else: discard