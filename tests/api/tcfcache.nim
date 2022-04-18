import std/[json, options, os]
import api/cfcache

block: # caching addons
  removeFile(getAddonFilename(123))

  let json = %* {
    "id": 123
  }
  doAssert getAddon(123).isNone()
  putAddon(json)
  doAssert getAddon(123).get() == json

block: # caching addons
  removeFile(getAddonFileFilename(456))

  let json = %* {
    "id": 456
  }
  doAssert getAddonFile(456).isNone()
  putAddonFile(json)
  doAssert getAddonFile(456).get() == json