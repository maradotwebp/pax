discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
  joinable: false
  batchable: false
  input: '''
y
testmodpack
testauthor
1.2.3
1.14.4
fabric
  '''
"""

import strutils, os, json
import cmd/init

block: # init fabric project
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  let manifest = readFile("./modpack/manifest.json").parseJson

  doAssert manifest["minecraft"]["version"].getStr == "1.14.4"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr.startsWith("fabric")
  doAssert manifest["version"].getStr == "1.2.3"
  doAssert manifest["author"].getStr == "testauthor"
  doAssert manifest["name"].getStr == "testmodpack"