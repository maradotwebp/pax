import std/[json, options]
import api/cfcache

cfcache.purge()

block: # caching addons
  let json = %* {
    "id": 123
  }
  doAssert getAddon(123).isNone()
  cfcache.putAddon(json)
  doAssert getAddon(123).get() == json

block: # caching addon files
  let json = %* {
    "id": 456
  }
  doAssert getAddonFile(456).isNone()
  cfcache.putAddonFile(json)
  doAssert getAddonFile(456).get() == json

block: # cleaning
  let numCleanedFiles = cfcache.clean()
  doAssert numCleanedFiles == 0