import modpack/version

block: # equality
  doAssert "1.16.4".Version == "1.16.4".Version
  doAssert "1.12.1".Version == "1.12.1".Version

block: # string casting
  doAssert "1.16.4" == "1.16.4".Version.`$`

block: # comparison
  doAssert "1.16.4".Version > "1.16.3".Version
  doAssert "1.16.5".Version > "1.16.1".Version
  doAssert "1.16.1".Version > "1.14.5".Version
  doAssert "1.16.1".Version < "1.17".Version
  doAssert not ("1.12.4".Version > "1.16.1".Version)
  doAssert "1.16.4".Version > "1.16-Snapshot".Version
  doAssert "1.16-Snapshot".Version > "1.14.4".Version
  doAssert "1.16.4".Version >= "1.16.4".Version
  doAssert "1.16.4".Version >= "1.16.3".Version
  doAssert "1.16.4".Version <= "1.16.4".Version
  doAssert "1.16-Snapshot".Version <= "1.16.3".Version

block: # `minor` function
  doAssert "1.16.4".Version.minor == "1.16".Version
  doAssert "1.12.4".Version.minor == "1.12".Version
  doAssert "1.13-Snapshot".Version.minor == "1.13".Version

block: # `proper` function
  doAssert @["1.16.4".Version, "Fabric".Version, "Forge".Version].proper == @["1.16.4".Version]
  doAssert @["Forge".Version, "1.12-Snapshot".Version].proper == @["1.12-Snapshot".Version]

