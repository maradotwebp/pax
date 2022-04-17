import std/[asyncdispatch, sequtils, strutils, sugar, options]
import api/metadata
import modpack/loader, modpack/version
import ../tutils

asyncBlock: # getModLoaderId on Fabric for versions
  let id = await getModloaderId("1.16.3".Version, Loader.Fabric)
  doAssert id != ""
asyncBlock:
  let id = await getModloaderId("1.17".Version, Loader.Fabric)
  doAssert id != ""
asyncBlock:
  let id = await getModloaderId("1.14.4".Version, Loader.Fabric)
  doAssert id != ""

asyncBlock: # getModLoaderId on Fabric for non-existing versions
  doAssertRaises(MetadataClientError):
    discard await getModloaderId("1.10.2".Version, Loader.Fabric)
asyncBlock:
  doAssertRaises(MetadataClientError):
    discard await getModloaderId("1.128.0".Version, Loader.Fabric)
asyncBlock:
  doAssertRaises(MetadataClientError):
    discard await getModloaderId("0.0.0".Version, Loader.Fabric)

asyncBlock: # getModLoaderId on Forge for versions
  let id = await getModloaderId("1.12.2".Version, Loader.Forge)
  doAssert id == "forge-14.23.5.2859"
asyncBlock:
  let id = await getModloaderId("1.12".Version, Loader.Forge)
  doAssert id == "forge-14.21.1.2387"
asyncBlock:
  let id = await getModloaderId("1.16.1".Version, Loader.Forge)
  doAssert id == "forge-32.0.108"

asyncBlock: # getModLoaderId on Forge for latest versions
  let id = await getModloaderId("1.12".Version, Loader.Forge, latest = true)
  doAssert id == "forge-14.21.1.2443"
asyncBlock:
  let id = await getModloaderId("1.16.1".Version, Loader.Forge, latest = true)
  doAssert id == "forge-32.0.108"

asyncBlock: # getModLoaderId on Forge for non-existing versions
  doAssertRaises(MetadataClientError):
    discard await getModloaderId("1.1.0".Version, Loader.Forge)
asyncBlock:
  doAssertRaises(MetadataClientError):
    discard await getModloaderId("1.128.0".Version, Loader.Forge)
asyncBlock:
  doAssertRaises(MetadataClientError):
    discard await getModloaderId("0.0.0".Version, Loader.Forge)

runTests()