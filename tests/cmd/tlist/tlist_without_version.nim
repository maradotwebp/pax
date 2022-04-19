discard """
    joinable: false
  batchable: false
  outputsub: '''
[Δ] ALL MODS (1)
 └─ •↑ Just Enough Items (JEI) - https://www.curseforge.com/minecraft/mc-mods/jei/files/3383205
       └─ • The installed mod is compatible with the modpack's minecraft version.
       └─ ↑ There is a newer version of this mod available.
  '''
"""

import std/[json, os]
import cmd/list
import term/color

disableTermColors()

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

  createDir("./modpack")
  writeFile("./modpack/manifest.json", manifestJson.pretty)
  paxList(status = true, info = false)
