discard """
  joinable: false
  batchable: false
  input: '''
y
  '''
"""

import std/[json, os]
import cmd/remove

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
    },
    {
      "projectID": 243121,
      "fileID": 3366626,
      "required": true,
      "__meta": {
        "name": "Quark",
        "explicit": true,
        "dependencies": [
          250363
        ]
      }
    },
    {
      "projectID": 250363,
      "fileID": 3326041,
      "required": true,
      "__meta": {
        "name": "AutoRegLib",
        "explicit": false,
        "dependencies": []
      }
    }
  ]
}

block:
  removeDir("./modpack/")

  createDir("./modpack")
  writeFile("./modpack/manifest.json", manifestJson.pretty)
  paxRemove("jei", strategy = "recommended")

  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["files"].getElems().len == 2
  doAssert manifest["files"][0]["__meta"]["name"].getStr() == "Quark"
  doAssert manifest["files"][1]["__meta"]["name"].getStr() == "AutoRegLib"