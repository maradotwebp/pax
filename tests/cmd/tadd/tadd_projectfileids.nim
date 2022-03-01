discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
  joinable: false
  batchable: false
  input: '''
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
  '''
"""

import json, os
import cmd/init, cmd/add

removeDir("./modpack")
paxInit(force = false, skipManifest = false, skipGit = true)
paxAdd("238222#3383214", noDepends = false, strategy = "recommended", addonType = "")
let manifest = readFile("./modpack/manifest.json").parseJson

doAssert fileExists("./modpack/manifest.json")
doAssert manifest["files"][0]["projectID"].getInt == 238222
doAssert manifest["files"][0]["fileID"].getInt == 3383214