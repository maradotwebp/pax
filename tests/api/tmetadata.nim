discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import asyncdispatch, strutils, options
import api/metadata
import modpack/loader, modpack/version

block: # getMcModloaderId - Fabric
  doAssert waitFor(getMcModloaderId("1.12.2".Version, Loader.fabric)).isNone
  doAssert waitFor(getMcModloaderId("1.128.0".Version, Loader.fabric)).isNone
  doAssert waitFor(getMcModloaderId("0.0.0".Version, Loader.fabric)).isNone
  # Fabric always returns the same preferred loader id
  let id1 = waitFor(getMcModloaderId("1.16.3".Version, Loader.fabric))
  doAssert id1.isSome
  let id2 = waitFor(getMcModloaderId("1.17".Version, Loader.fabric))
  doAssert id2.isSome
  let id3 = waitFor(getMcModloaderId("1.14.4".Version, Loader.fabric))
  doAssert id3.isSome
  let id4 = waitFor(getMcModloaderId("1.16.1".Version, Loader.fabric))
  doAssert id4.isSome
  doAssert id1.get() == id2.get()
  doAssert id3.get() == id4.get()
  doAssert id1.get() == id3.get()
  doAssert id1.get().startsWith("fabric-")

block: # getMcModloaderId - Forge
  doAssert waitFor(getMcModloaderId("1.128.0".Version, Loader.forge)).isNone
  doAssert waitFor(getMcModloaderId("0.0.0".Version, Loader.forge)).isNone
  doAssert waitFor(getMcModloaderId("1.1.0".Version, Loader.forge)).isNone
  ## Forge returns a specific loader id
  doAssert waitFor(getMcModloaderId("1.12.2".Version, Loader.forge)).get() == "forge-14.23.5.2855"
  doAssert waitFor(getMcModloaderId("1.12".Version, Loader.forge)).get() == "forge-14.21.1.2387"
  doAssert waitFor(getMcModloaderId("1.16.1".Version, Loader.forge)).get() == "forge-32.0.108"
  doAssert waitFor(getMcModloaderId("1.16.3".Version, Loader.forge)).get() == "forge-34.1.0"
