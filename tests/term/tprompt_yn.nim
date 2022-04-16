discard """
  input: '''

e
y
a
Y
w
n
M
N
  '''

  disabled: "win"
"""

import term/prompt

doAssert promptYn("True or false", default = true) == true
doAssert promptYn("Test with y", default = false) == true
doAssert promptYn("Test with Y", default = false) == true
doAssert promptYn("Test with n", default = true) == false
doAssert promptYn("Test with N", default = true) == false