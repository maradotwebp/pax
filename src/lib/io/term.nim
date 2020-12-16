import strutils

template clrRed*(text: string): string = "\e[31m" & text & "\e[0m"
template clrGreen*(text: string): string = "\e[32m" & text & "\e[0m"
template clrYellow*(text: string): string = "\e[33m" & text & "\e[0m"
template clrBlue*(text: string): string = "\e[34m" & text & "\e[0m"
template clrMagenta*(text: string): string = "\e[35m" & text & "\e[0m"
template clrCyan*(text: string): string = "\e[36m" & text & "\e[0m"
template clrGray*(text: string): string = "\e[90m" & text & "\e[0m"

template wrapIcon(content: string): string = "[" & content & "]"

const
  # Icons
  debugIcon* = wrapIcon ":".clrGray
  infoIcon* = wrapIcon "-".clrGreen
  warnIcon* = wrapIcon "!".clrYellow
  errorIcon* = wrapIcon "X".clrRed
  rootIcon* = wrapIcon "Δ".clrMagenta
  # Prefixes
  promptPrefix* = " └─ "