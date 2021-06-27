discard """
  input: '''
Teststring

hello

wrongChoiceC
wrongChoiceD
a
50


10
9999999999999
-10
1
benjamin

ab
cd
ef
gh
y
lol
this
works

truthy
falsy

y
Y
n
N
  '''
"""

import cli/prompt

block: # prompt
  # default prompt
  doAssert prompt("Enter a string") == "Teststring"
  doAssert prompt("Enter anything") == "hello"
  # prompt with choices
  doAssert prompt("Enter either a or b", choices = @["a", "b"]) == "a"
  doAssert prompt("Number between 1 and 3", choices = @["1", "2", "3"]) == "1"
  # prompt with default value
  doAssert prompt("Enter your name or nothing", default = "ben") == "benjamin"
  doAssert prompt("Enter a number", default = "1") == "1"
  # prompt with choices and default value
  doAssert prompt("Either x or y", choices = @["x", "y"], default = "x") == "y"
  doAssert prompt("Either e or f", choices = @["e", "f"], default = "f") == "f"

block: # promptYN
  doAssert promptYn("True or false", default = true) == true
  doAssert promptYn("Test with y", default = false) == true
  doAssert promptYn("Test with Y", default = false) == true
  doAssert promptYn("Test with n", default = true) == false
  doAssert promptYn("Test with N", default = true) == false

  skipYNSetting = true

  doAssert promptYn("True or false", default = true) == true
  doAssert promptYn("Test with y", default = false) == true
  doAssert promptYn("Test with Y", default = false) == true
  doAssert promptYn("Test with n", default = true) == true
  doAssert promptYn("Test with N", default = true) == true