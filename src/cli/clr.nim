import terminal, unicode

var
  isTerminalColorEnabled* = true

type
  TermOutKind = enum
    ## the kind of a TermOutPart.
    ## can either be a foreground styling `okForeground`,
    ## a background styling `okBackground`,
    ## a styling `okStyle`
    ## or normal text `okString`,
    okForeground,
    okBackground,
    okStyle,
    okReset,
    okString

  TermOutPart = ref object
    ## the part of output that is either styling or text.
    ## has a `kind` property to determine the type.
    case kind: TermOutKind
    of okForeground: fgColor: ForegroundColor
    of okBackground: bgColor: BackgroundColor
    of okStyle: style: Style
    of okReset: discard
    of okString: text: string
  
  TermOut* = seq[TermOutPart]

converter toTermOutPart*(str: string): TermOutPart =
  result = TermOutPart(kind: okString, text: str)

converter toTermOut*(str: string): TermOut =
  return @[toTermOutPart(str)]

proc style*(termout: TermOut, style: Style): TermOut =
  ## applies a style to termout.
  let pre = TermOutPart(kind: okStyle, style: style)
  let post = TermOutPart(kind: okReset)
  return pre & termOut & post

template bright*(termout: TermOut): TermOut = termout.style(styleBright)
template dim*(termout: TermOut): TermOut = termout.style(styleDim)
template italic*(termout: TermOut): TermOut = termout.style(styleItalic)
template underscore*(termout: TermOut): TermOut = termout.style(styleUnderscore)
template blink*(termout: TermOut): TermOut = termout.style(styleBlink)
template blinkRapid*(termout: TermOut): TermOut = termout.style(styleBlinkRapid)
template reverse*(termout: TermOut): TermOut = termout.style(styleReverse)
template hidden*(termout: TermOut): TermOut = termout.style(styleHidden)
template strikethrough*(termout: TermOut): TermOut = termout.style(styleStrikethrough)

proc fg*(termOut: TermOut, fg: ForegroundColor): TermOut =
  ## applies a foreground color to termout.
  let pre = TermOutPart(kind: okForeground, fgColor: fg)
  let post = TermOutPart(kind: okReset)
  return pre & termOut & post

template blackFg*(termout: TermOut): TermOut = termout.fg(fgBlack)
template redFg*(termout: TermOut): TermOut = termout.fg(fgRed)
template greenFg*(termout: TermOut): TermOut = termout.fg(fgGreen)
template yellowFg*(termout: TermOut): TermOut = termout.fg(fgYellow)
template blueFg*(termout: TermOut): TermOut = termout.fg(fgBlue)
template magentaFg*(termout: TermOut): TermOut = termout.fg(fgMagenta)
template cyanFg*(termout: TermOut): TermOut = termout.fg(fgCyan)
template whiteFg*(termout: TermOut): TermOut = termout.fg(fgWhite)
template defaultFg*(termout: TermOut): TermOut = termout.fg(fgDefault)

proc bg*(termout: TermOut, bg: BackgroundColor): TermOut =
  ## applies a background color to termout.
  let pre = TermOutPart(kind: okBackground, bgColor: bg)
  let post = TermOutPart(kind: okReset)
  return pre & termOut & post

template blackBg*(termout: TermOut): TermOut = termout.bg(bgBlack)
template redBg*(termout: TermOut): TermOut = termout.bg(bgRed)
template greenBg*(termout: TermOut): TermOut = termout.bg(bgGreen)
template yellowBg*(termout: TermOut): TermOut = termout.bg(bgYellow)
template blueBg*(termout: TermOut): TermOut = termout.bg(bgBlue)
template magentaBg*(termout: TermOut): TermOut = termout.bg(bgMagenta)
template cyanBg*(termout: TermOut): TermOut = termout.bg(bgCyan)
template whiteBg*(termout: TermOut): TermOut = termout.bg(bgWhite)
template defaultBg*(termout: TermOut): TermOut = termout.bg(bgDefault)

proc clrWrite*(args: varargs[TermOut]): void =
  ## prints TermOut to console.
  for arg in args:
    for part in arg:
      case part.kind:
        of okForeground:
          if isTerminalColorEnabled:
            stdout.setForegroundColor(part.fgColor)
        of okBackground:
          if isTerminalColorEnabled:
            stdout.setBackgroundColor(part.bgColor)
        of okStyle:
          if isTerminalColorEnabled:
            stdout.setStyle({part.style})
        of okReset:
          if isTerminalColorEnabled:
            stdout.resetAttributes()
        of okString:
          stdout.write(part.text)

proc clrWriteLine*(args: varargs[TermOut]): void =
  clrWrite(args)
  stdout.write("\n")

proc echoClr*(args: varargs[TermOut]): void =
  clrWriteLine(args)

proc strLen*(term: TermOut): Natural =
  result = 0
  for part in term:
    if part.kind == okString:
      result += part.text.runeLen