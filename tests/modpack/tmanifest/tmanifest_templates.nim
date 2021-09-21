discard """
  joinable: false
  batchable: false
"""

import os
import modpack/loader, modpack/manifest, modpack/version

block: # rejectInstalledMod
  let m = Manifest()
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version
  m.files = @[ManifestFile(projectId: 1234, fileId: 100)]

  let f = proc(projectId: int): int =
    result = -1
    m.rejectInstalledAddon(projectId)
    result = 1

  doAssert f(1234) == -1
  doAssert f(9999) == 1

block: # requirePaxProject
  let f = proc(): int =
    result = -1
    requirePaxProject()
    result = 1

  removeDir(packFolder)

  doAssert f() == -1

  createDir(packFolder)
  createDir(overridesFolder)
  writeFile(manifestFile, "Hello pax test")
  defer: removeDir(packFolder)

  doAssert f() == 1

block: # rejectPaxProject
  let f = proc(): int =
    result = -1
    rejectPaxProject()
    result = 1

  removeDir(packFolder)

  doAssert f() == 1

  createDir(packFolder)
  createDir(overridesFolder)
  writeFile(manifestFile, "Hello pax test")
  defer: removeDir(packFolder)

  doAssert f() == -1