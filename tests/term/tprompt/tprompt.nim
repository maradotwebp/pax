discard """
  input: '''
Teststring

hello
  '''

  disabled: "win"
"""

import term/prompt

doAssert prompt("Enter a string") == "Teststring"
doAssert prompt("Enter anything") == "hello"