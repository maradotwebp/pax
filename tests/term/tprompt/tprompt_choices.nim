discard """
  input: '''

wrongChoiceC
wrongChoiceD
a
50

10
9999999999999
-10
1
  '''

  disabled: "win"
"""

import term/prompt

doAssert prompt("Enter either a or b", choices = @["a", "b"]) == "a"
doAssert prompt("Number between 1 and 3", choices = @["1", "2", "3"]) == "1"