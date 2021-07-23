discard """"""

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

