import terminal

export terminal

const
  # icons
  debugIcon = ":"
  infoIcon = "-"
  warnIcon = "!"
  errorIcon = "x"
  rootIcon = "Δ"
  # prefixes
  indentPrefix* = " └─ "

template echoWithIcon(icon: string, color: typed, args: varargs[untyped]): void =
  ## print a message with an icon
  styledEcho "[", color, icon, resetStyle, "] ", args

template echoDebug*(args: varargs[untyped]): void = echoWithIcon(debugIcon, styleDim, args)
template echoInfo*(args: varargs[untyped]): void = echoWithIcon(infoIcon, fgGreen, args)
template echoWarn*(args: varargs[untyped]): void = echoWithIcon(warnIcon, fgYellow, args)
template echoError*(args: varargs[untyped]): void = echoWithIcon(errorIcon, fgRed, args)
template echoRoot*(args: varargs[untyped]): void = echoWithIcon(rootIcon, fgMagenta, args)