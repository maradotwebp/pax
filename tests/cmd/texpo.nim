discard """"""

import json, os, zippy/ziparchives
import cli/clr
import cmd/expo

terminalColorEnabledSetting = false

block: # export .zip
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

block: # export .zip to custom location
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
  paxExport(path = "./completely-custom-out-dir/somewhere/here.zip")
  defer: removeDir("./completely-custom-out-dir/somewhere/")
  defer: removeDir("./completely-custom-out-dir/")

  doAssert fileExists("./completely-custom-out-dir/somewhere/here.zip")

  removeDir("./modpack")
  extractAll("./completely-custom-out-dir/somewhere/here.zip", "./modpack")

  doAssert parseFile("./modpack/manifest.json") == manifestJson