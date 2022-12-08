discard """
  joinable: false
  batchable: false
  input: '''
y
testmodpack
testauthor
1.2.3
1.18.2
quilt
  '''
"""

import std/[sequtils, strutils, sugar, os, json]
import cmd/init

block:
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  let manifest = readFile("./modpack/manifest.json").parseJson

  doAssert manifest["minecraft"]["version"].getStr == "1.18.2"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr.startsWith("forge")
  doAssert manifest["version"].getStr == "1.2.3"
  doAssert manifest["author"].getStr == "testauthor"
  doAssert manifest["name"].getStr == "testmodpack"
  doAssert manifest["files"].getElems.filter(f => f["projectID"].getInt == 640265).len > 0