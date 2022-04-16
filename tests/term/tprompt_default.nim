discard """
  input: '''
benjamin

  '''

  disabled: "win"
"""

import term/prompt

doAssert prompt("Enter your name or nothing", default = "ben") == "benjamin"
doAssert prompt("Enter a number", default = "1") == "1"