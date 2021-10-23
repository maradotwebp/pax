discard """
  output: '''
Hi this should work!
Wow how nice if this worked!
Hello! I hope this works..
Well, I don't think it helps testing this without colors..
But without colors output should be consistent at least.
Concat works too? [RED][BLUE]
  '''
"""

import term/color

terminalColorEnabledSetting = false

block: # clrWrite
  clrWrite(stdout, "Hi ")
  clrWrite(stdout, "this ".italic)
  clrWrite(stdout, "should ".bgBlack)
  clrWrite(stdout, "work!")
  clrWrite(stdout, "\n")

block: # clrWriteLine
  clrWriteLine(stdout, "Wow".bgWhite & " how nice", " if ".strikethrough, "this worked!")

block: # echoClr
  echoClr "Hello! I hope this works.."
  echoClr "Well, I don't think it helps testing this ", "without".fgRed, " colors.."
  echoClr "But without colors output should be ", "consistent".fgBlack.bgWhite, " at least."
  echoClr "Concat works too? ", "[RED]".fgRed & "[BLUE]".fgBlue