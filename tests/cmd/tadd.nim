discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"

  input: '''
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
-
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
-
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
-
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
-
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
-
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
-
y
testmodpack
testauthor
1.0.0
1.16.5
forge
1
y
-
  '''
"""

import json, os
import cli/clr
import cmd/init, cmd/add

terminalColorEnabledSetting = false

block: # add with search
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  doAssert fileExists("./modpack/manifest.json")
  paxAdd("jei", noDepends = false, strategy = "recommended")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"][0]["projectID"].getInt == 238222
  doAssert stdin.readLine() == "-"
  echo "-"

block: # add with multi-string search
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  doAssert fileExists("./modpack/manifest.json")
  paxAdd("just enough items", noDepends = false, strategy = "recommended")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"][0]["projectID"].getInt == 238222
  doAssert stdin.readLine() == "-"
  echo "-"

block: # add with cf file string
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  doAssert fileExists("./modpack/manifest.json")
  paxAdd("https://www.curseforge.com/minecraft/mc-mods/jei/files/3383214", noDepends = false, strategy = "recommended")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"][0]["projectID"].getInt == 238222
  doAssert manifest["files"][0]["fileID"].getInt == 3383214
  doAssert stdin.readLine() == "-"
  echo "-"

block: # add with cf string
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  doAssert fileExists("./modpack/manifest.json")
  paxAdd("https://www.curseforge.com/minecraft/mc-mods/jei", noDepends = false, strategy = "recommended")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"][0]["projectID"].getInt == 238222
  doAssert stdin.readLine() == "-"
  echo "-"

block: # add with <projectid>#<fileid> string
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  doAssert fileExists("./modpack/manifest.json")
  paxAdd("238222#3383214", noDepends = false, strategy = "recommended")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"][0]["projectID"].getInt == 238222
  doAssert manifest["files"][0]["fileID"].getInt == 3383214
  doAssert stdin.readLine() == "-"
  echo "-"

block: # add with <projectid> string
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  doAssert fileExists("./modpack/manifest.json")
  paxAdd("238222", noDepends = false, strategy = "recommended")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"][0]["projectID"].getInt == 238222
  doAssert stdin.readLine() == "-"
  echo "-"

block: # prevent adding same mods
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  doAssert fileExists("./modpack/manifest.json")
  paxAdd("just enough items", noDepends = false, strategy = "recommended")
  paxAdd("238222", noDepends = false, strategy = "recommended")
  paxAdd("238222#3383214", noDepends = false, strategy = "recommended")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"].getElems().len == 1
  doAssert manifest["files"][0]["projectID"].getInt == 238222
  doAssert stdin.readLine() == "-"
  echo "-"