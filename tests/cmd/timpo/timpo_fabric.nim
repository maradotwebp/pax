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
  client.downloadFile("https://edge.forgecdn.net/files/3392/479/Fabulously Optimized-2.1.0-beta.1.zip", "./test-fabric-modpack.zip")
  defer: removeFile("./test-fabric-modpack.zip")

  paxImport("./test-fabric-modpack.zip", force = false, skipGit = true)
  let manifest = readFile("./modpack/manifest.json").parseJson

  doAssert manifest["minecraft"]["version"].getStr == "1.17.1"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr.startsWith("fabric")
  doAssert manifest["version"].getStr == "2.1.0-beta.1"
  doAssert manifest["author"].getStr == "robotkoer"
  doAssert manifest["name"].getStr == "Fabulously Optimized"