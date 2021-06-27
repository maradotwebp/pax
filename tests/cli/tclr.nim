discard """
  output: '''
Hello! I hope this works..
Well, I don't think it helps testing this without colors..
But without colors output should be consistent at least.
Concat works too? [RED][BLUE]
  '''
"""

import cli/clr

terminalColorEnabledSetting = false

block: # echoClr
  echoClr "Hello! I hope this works.."
  echoClr "Well, I don't think it helps testing this ", "without".redFg, " colors.."
  echoClr "But without colors output should be ", "consistent".whiteBg.blackFg, " at least."
  echoClr "Concat works too? ", "[RED]".redFg & "[BLUE]".blueFg