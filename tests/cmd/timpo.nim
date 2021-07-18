discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import httpclient, json, strutils, os
import cli/clr
import cmd/impo

terminalColorEnabledSetting = false

block: # import forge modpack
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

block: # import fabric modpack
  removeDir("./modpack")

  let client = newHttpClient()
  client.downloadFile("https://edge.forgecdn.net/files/3392/479/Fabulously Optimized-2.1.0-beta.1.zip", "./test-fabric-modpack.zip")
  defer: removeFile("./test-fabric-modpack.zip")

  paxImport("./test-fabric-modpack.zip", force = false, skipGit = true)
  let manifest = readFile("./modpack/manifest.json").parseJson

  doAssert manifest["minecraft"]["version"].getStr == "1.17.1"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr.startsWith("fabric")
  doAssert manifest["version"].getStr == "2.1.0-beta.1"
  doAssert manifest["author"].getStr == "robotkoer"
  doAssert manifest["name"].getStr == "Fabulously Optimized"