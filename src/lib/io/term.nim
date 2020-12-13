import macros, strformat

template red*(text: string): string = "\e[31m" & text & "\e[0m"
template green*(text: string): string = "\e[32m" & text & "\e[0m"
template yellow*(text: string): string = "\e[33m" & text & "\e[0m"
template blue*(text: string): string = "\e[34m" & text & "\e[0m"
template magenta*(text: string): string = "\e[35m" & text & "\e[0m"
template cyan*(text: string): string = "\e[36m" & text & "\e[0m"
template gray*(text: string): string = "\e[90m" & text & "\e[0m"

template debug*(): string = "[" & ":".gray & "]"
template info*(): string = "[-]"
template warn*(): string = "[" & "!".yellow & "]"
template error*(): string = "[" & "X".red & "]"

macro unpackArgsWithPrefix(callee: untyped; pre: string; args: varargs[untyped]): untyped =
  result = newCall(callee)
  result.add pre
  for i in 0 ..< args.len:
    result.add args[i]

template echoDebug*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, debug() & " ", args)
template echoInfo*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, info() & " ", args)
template echoWarn*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, warn() & " ", args)
template echoError*(args: varargs[string, `$`]): void = unpackArgsWithPrefix(echo, error() & " ", args)

proc readInput*(text: string, prefix = " └ "): string =
  while true:
    stdout.write prefix, text, ": "
    result = readLine(stdin)
    case result:
      of "": discard
      else: break

proc readInput*(text: string, default: string, prefix = " └ "): string =
  stdout.write prefix, text, fmt" (default: {default.cyan}): "
  var input: string = readLine(stdin)
  result = if input != "": input else: default

proc readYesNo*(text: string, prefix = " └ "): bool =
  while true:
    stdout.write prefix, text, " (", "y/n".cyan, "): "
    case readLine(stdin):
      of "y", "Y", "Yes", "yes", "YES": return true
      of "n", "N", "No", "no", "NO": return false
      else: discard

proc readYesNo*(text: string, default: char, prefix = " └ "): bool =
  while true:
    stdout.write prefix, text, " (", "y/n".cyan, " - default: ", ($default).cyan, "): "
    case readLine(stdin):
      of "y", "Y", "Yes", "yes", "YES": return true
      of "n", "N", "No", "no", "NO": return false
      of "":
        case default:
          of 'y': return true
          of 'n': return false
          else: assert(false)
      else: discard