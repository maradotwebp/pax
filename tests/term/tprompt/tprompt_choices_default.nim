discard """
  input: '''
ab
cd
ef
gh
y
lol
this
works

  '''

  disabled: "win"
"""

import term/prompt

doAssert prompt("Either x or y", choices = @["x", "y"], default = "x") == "y"
doAssert prompt("Either e or f", choices = @["e", "f"], default = "f") == "f"