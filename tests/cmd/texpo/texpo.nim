discard """
  joinable: false
  batchable: false
"""

import json, os, zippy/ziparchives
import cmd/expo

block:
  removeDir("./.out/")
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
        "fileID": 3383214,
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
  paxExport(path = "")

  doAssert fileExists("./.out/testmodpack123.zip")

  removeDir("./modpack")
  extractAll("./.out/testmodpack123.zip", "./modpack")

  doAssert parseFile("./modpack/manifest.json") == manifestJson