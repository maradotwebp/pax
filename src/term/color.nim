## Module for printing colored output to the terminal.
## 
## The nim stdlib has support for writing colored output in the `terminal` library:
## 
## .. code-block:: nim
##    import terminal
##    styledEcho fgRed, "red text", fgReset, fgGreen, bgBlue, "green text"
##
## but this style lacks a few features that were required for pax, like
## - being able to return strings with color already attached to them from procedures
##   (not doable with `terminal` due to `styledWrite` taking varargs)
## - conditional styling
## 
## This `termcolor` package uses a different paradigm which allows another style:
## 
## .. code-block:: nim
##    import term/color
##    echoClr "red text".fgRed, "green text".fgGreen.bgBlue
## 
## Not only does this feel more "natural" to me, it also simplifies chaining and
## allows for all the missing features mentioned above.

import terminal, unicode

var
  ## if false, terminal color will be disabled.
  terminalColorEnabledSetting* = true

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

converter toTermOut*(str: string): TermOut =
  ## convienience converter so that strings can be passed to `clrWrite`.
  return @[TermOutPart(kind: okString, text: str)]

proc style*(termout: TermOut, style: Style): TermOut =
  ## applies `style` to termout.
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

proc fg*(termout: TermOut, fg: ForegroundColor): TermOut =
  ## applies `fg` to termout.
  let pre = TermOutPart(kind: okForeground, fgColor: fg)
  let post = TermOutPart(kind: okReset)
  return pre & termout & post

template fgBlack*(termout: TermOut): TermOut = termout.fg(terminal.fgBlack)
template fgRed*(termout: TermOut): TermOut = termout.fg(terminal.fgRed)
template fgGreen*(termout: TermOut): TermOut = termout.fg(terminal.fgGreen)
template fgYellow*(termout: TermOut): TermOut = termout.fg(terminal.fgYellow)
template fgBlue*(termout: TermOut): TermOut = termout.fg(terminal.fgBlue)
template fgMagenta*(termout: TermOut): TermOut = termout.fg(terminal.fgMagenta)
template fgCyan*(termout: TermOut): TermOut = termout.fg(terminal.fgCyan)
template fgWhite*(termout: TermOut): TermOut = termout.fg(terminal.fgWhite)
template fgDefault*(termout: TermOut): TermOut = termout.fg(terminal.fgDefault)

proc bg*(termout: TermOut, bg: BackgroundColor): TermOut =
  ## applies a background color to termout.
  let pre = TermOutPart(kind: okBackground, bgColor: bg)
  let post = TermOutPart(kind: okReset)
  return pre & termOut & post

template bgBlack*(termout: TermOut): TermOut = termout.bg(terminal.bgBlack)
template bgRed*(termout: TermOut): TermOut = termout.bg(terminal.bgRed)
template bgGreen*(termout: TermOut): TermOut = termout.bg(terminal.bgGreen)
template bgYellow*(termout: TermOut): TermOut = termout.bg(terminal.bgYellow)
template bgBlue*(termout: TermOut): TermOut = termout.bg(terminal.bgBlue)
template bgMagenta*(termout: TermOut): TermOut = termout.bg(terminal.bgMagenta)
template bgCyan*(termout: TermOut): TermOut = termout.bg(terminal.bgCyan)
template bgWhite*(termout: TermOut): TermOut = termout.bg(terminal.bgWhite)
template bgDefault*(termout: TermOut): TermOut = termout.bg(terminal.bgDefault)

proc clrWrite*(f: File, args: varargs[TermOut]): void =
  ## prints (optionally colored) strings to the given file.
  for arg in args:
    for part in arg:
      case part.kind:
        of okForeground:
          if terminalColorEnabledSetting:
            f.setForegroundColor(part.fgColor)
        of okBackground:
          if terminalColorEnabledSetting:
            f.setBackgroundColor(part.bgColor)
        of okStyle:
          if terminalColorEnabledSetting:
            f.setStyle({part.style})
        of okReset:
          if terminalColorEnabledSetting:
            f.resetAttributes()
        of okString:
          f.write(part.text)

template clrWriteLine*(f: File, args: varargs[TermOut]): void =
  ## calls `clrWrite` and appends a `\n` at the end.
  clrWrite(f, args)
  f.write("\n")

template echoClr*(args: varargs[TermOut]): void =
  ## convenience function for echoing colored output to stdout.
  clrWriteLine(stdout, args)

proc strLen*(term: TermOut): Natural =
  ## returns the length of a terminal string.
  result = 0
  for part in term:
    if part.kind == okString:
      result += part.text.runeLen