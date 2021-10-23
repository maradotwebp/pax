discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
  joinable: false
  batchable: false
  input: '''
y
  '''
"""

import json, os
import cmd/pin, term/color

terminalColorEnabledSetting = false

block:
  removeDir("./modpack/")

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
          "pinned": false,
          "dependencies": []
        }
      }
    ]
  }

  createDir("./modpack")
  writeFile("./modpack/manifest.json", manifestJson.pretty)

  paxPin("jei")

  let newManifestJson = readFile("./modpack/manifest.json").parseJson
  doAssert newManifestJson["files"][0]["__meta"]["pinned"].getBool() == true