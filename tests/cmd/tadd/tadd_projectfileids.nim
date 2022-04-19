discard """
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

import std/[json, os]
import cmd/[add, init]

removeDir("./modpack")
paxInit(force = false, skipManifest = false, skipGit = true)
paxAdd("238222#3383214", noDepends = false, strategy = "recommended", addonType = "")
let manifest = readFile("./modpack/manifest.json").parseJson

doAssert fileExists("./modpack/manifest.json")
doAssert manifest["files"][0]["projectID"].getInt == 238222
doAssert manifest["files"][0]["fileID"].getInt == 3383214