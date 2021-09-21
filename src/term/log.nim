## Module for logging to the terminal - in a pretty way.
## 
## Provides logging on various levels (debug, info, warning, error).
## Prefixes each level with a different icon so that logs can be easily
## distinguished even if the terminal doesn't support color output.

import color
export color

const
  # icons
  debugIcon = ":"
  infoIcon = "-"
  warnIcon = "!"
  errorIcon = "x"
  rootIcon = "Δ"
  # prefixes
  indentPrefix* = " └─ "

template echoIcon(icon: TermOut, args: varargs[untyped]): void =
  ## print a message with an icon
  echoClr "[", icon, "]", " ", args

template echoDebug*(args: varargs[untyped]): void = echoIcon(debugIcon.dim, args)
template echoInfo*(args: varargs[untyped]): void = echoIcon(infoIcon.fgGreen, args)
template echoWarn*(args: varargs[untyped]): void = echoIcon(warnIcon.fgYellow, args)
template echoError*(args: varargs[untyped]): void = echoIcon(errorIcon.fgRed, args)
template echoRoot*(args: varargs[untyped]): void = echoIcon(rootIcon.fgMagenta, args)