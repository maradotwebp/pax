import clr

export clr

const
  # icons
  debugIcon = ":"
  infoIcon = "-"
  warnIcon = "!"
  errorIcon = "x"
  rootIcon = "Δ"
  # prefixes
  indentPrefix* = " └─ "

template echoWithIcon(icon: TermOut, args: varargs[untyped]): void =
  ## print a message with an icon
  echoClr "[", icon, "]", " ", args

template echoDebug*(args: varargs[untyped]): void = echoWithIcon(debugIcon.dim, args)
template echoInfo*(args: varargs[untyped]): void = echoWithIcon(infoIcon.greenFg, args)
template echoWarn*(args: varargs[untyped]): void = echoWithIcon(warnIcon.yellowFg, args)
template echoError*(args: varargs[untyped]): void = echoWithIcon(errorIcon.redFg, args)
template echoRoot*(args: varargs[untyped]): void = echoWithIcon(rootIcon.magentaFg, args)