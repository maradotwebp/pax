discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
  joinable: false
  batchable: false
"""

import httpclient, json, strutils, os
import cmd/impo

block:
  removeDir("./modpack")

  let client = newHttpClient()
  client.downloadFile("https://edge.forgecdn.net/files/3318/579/Origin SMP-1.6.zip", "./test-forge-modpack.zip")
  defer: removeFile("./test-forge-modpack.zip")

  paxImport("./test-forge-modpack.zip", force = false, skipGit = true)
  let manifest = readFile("./modpack/manifest.json").parseJson

  doAssert manifest["minecraft"]["version"].getStr == "1.16.5"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr.startsWith("forge")
  doAssert manifest["version"].getStr == "1.6"
  doAssert manifest["name"].getStr == "Origin SMP"