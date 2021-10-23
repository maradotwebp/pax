import term/prompt

skipYNSetting = true

doAssert promptYn("True or false", default = true) == true
doAssert promptYn("Test with y", default = false) == true
doAssert promptYn("Test with Y", default = false) == true
doAssert promptYn("Test with n", default = true) == true
doAssert promptYn("Test with N", default = true) == true