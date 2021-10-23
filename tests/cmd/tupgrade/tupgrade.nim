discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
  joinable: false
  batchable: false
  input: '''
y
'''
"""

import json, os
import cmd/upgrade

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
      "projectID": 60089,
      "fileID": 2849221,
      "required": true,
      "__meta": {
        "name": "Mouse Tweaks",
        "explicit": true,
        "dependencies": []
      }
    },
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

block: # update mod
  removeDir("./modpack/")

  createDir("./modpack")
  writeFile("./modpack/manifest.json", manifestJson.pretty)
  paxUpgrade(strategy = "recommended")

  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"].getElems().len == 2
  doAssert manifest["files"][0]["fileID"].getInt() > 2849221
  doAssert manifest["files"][1]["fileID"].getInt() > 3383205