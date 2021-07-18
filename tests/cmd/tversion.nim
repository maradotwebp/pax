discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import json, os, strutils
import cli/clr
import cmd/version

terminalColorEnabledSetting = false

let manifestJson = %* {
  "minecraft": {
    "version": "1.16.5",
    "modLoaders": [
      {
        "id": "forge-36.1.0",
        "primary": true
      }
    ]
  },
  "manifestType": "minecraftModpack",
  "overrides": "overrides",
  "manifestVersion": 1,
  "version": "1.0.0",
  "author": "testauthor",
  "name": "testmodpack123",
  "files": [
    {
      "projectID": 238222,
      "fileID": 3383205,
      "required": true,
      "__meta": {
        "name": "Just Enough Items (JEI)",
        "explicit": true,
        "dependencies": []
      }
    }
  ]
}

block: # switch mc version
  removeDir("./modpack/")

  createDir("./modpack")
  writeFile("./modpack/manifest.json", manifestJson.pretty)
  
  paxVersion("1.12.2")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["minecraft"]["version"].getStr() == "1.12.2"

block: # switch mc version & loader
  removeDir("./modpack/")

  createDir("./modpack")
  writeFile("./modpack/manifest.json", manifestJson.pretty)
  
  paxVersion("1.17.1", loader = "fabric")
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["minecraft"]["version"].getStr() == "1.17.1"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr().startsWith("fabric")

block: # prevent invalid versions
  removeDir("./modpack/")

  createDir("./modpack")
  writeFile("./modpack/manifest.json", manifestJson.pretty)
  
  paxVersion("1.12.2")
  var manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["minecraft"]["version"].getStr() == "1.12.2"

  paxVersion("10.11.12")
  manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["minecraft"]["version"].getStr() == "1.12.2"

  paxVersion("1.16.100")
  manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["minecraft"]["version"].getStr() == "1.12.2"