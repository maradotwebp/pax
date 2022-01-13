discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import asyncdispatch, sequtils, strutils, sugar, options
import api/metadata
import modpack/loader, modpack/version

block: # getModloaderId - Fabric
  let id1 = getModloaderId("1.10.2".Version, Loader.Fabric)
  let id2 = getModloaderId("1.128.0".Version, Loader.Fabric)
  let id3 = getModloaderId("0.0.0".Version, Loader.Fabric)
  let id4 = getModloaderId("1.16.3".Version, Loader.Fabric)
  let id5 = getModloaderId("1.17".Version, Loader.Fabric)
  let id6 = getModloaderId("1.14.4".Version, Loader.Fabric)
  let id7 = getModloaderId("1.16.1".Version, Loader.Fabric)

  let allIdPromises = @[id1, id2, id3, id4, id5, id6, id7]
  let allIds = waitFor(all(allIdPromises))

  doAssert id1.read().isNone()
  doAssert id2.read().isNone()
  doAssert id3.read().isNone()
  doAssert id4.read().isSome()
  doAssert id5.read().isSome()
  doAssert id6.read().isSome()
  doAssert id7.read().isSome()
  doAssert allIds.filter((x) => x.isSome()).all((x) => x.get().startsWith("fabric-"))

block: # getModloaderId - Forge
  let id1 = getModloaderId("1.128.0".Version, Loader.Forge)
  let id2 = getModloaderId("0.0.0".Version, Loader.Forge)
  let id3 = getModloaderId("1.1.0".Version, Loader.Forge)
  let id4 = getModloaderId("1.12.2".Version, Loader.Forge)
  let id5 = getModloaderId("1.12".Version, Loader.Forge)
  let id6 = getModloaderId("1.16.1".Version, Loader.Forge)
  let id7 = getModloaderId("1.16.3".Version, Loader.Forge)
  let id8 = getModloaderId("1.12".Version, Loader.Forge, latest=true)
  let id9 = getModloaderId("1.16.1".Version, Loader.Forge, latest=true)
  let id10 = getModloaderId("1.16.3".Version, Loader.Forge, latest=true)

  let allIdPromises = @[id1, id2, id3, id4, id5, id6, id7, id8, id9, id10]
  discard waitFor(all(allIdPromises))

  doAssert id1.read().isNone()
  doAssert id2.read().isNone()
  doAssert id3.read().isNone()
  doAssert id4.read().get() == "forge-14.23.5.2859"
  doAssert id5.read().get() == "forge-14.21.1.2387"
  doAssert id6.read().get() == "forge-32.0.108"
  doAssert id7.read().get() == "forge-34.1.0"
  doAssert id8.read().get() == "forge-14.21.1.2443"
  doAssert id9.read().get() == "forge-32.0.108"
  doAssert id10.read().get() == "forge-34.1.42"