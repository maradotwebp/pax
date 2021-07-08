discard """"""

import mc/version, modpack/files, modpack/loader, random, os

randomize()

block: # manifest loader
  var m: Manifest
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version

  m.mcModloaderId = "fabric-0.11.0"
  doAssert m.loader == Loader.fabric

  m.mcModloaderId = "forge-34.1.0"
  doAssert m.loader == Loader.forge

block: # manifest mods
  var m: Manifest
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version

  doAssert m.files.len == 0

  m.installMod(initManifestFile(
      projectId = 111,
      fileId = 200,
      initManifestMetadata(
        name = "test",
        explicit = true,
        installOn = "both",
        dependencies = @[]
      )
    )
  )
  doAssert m.files.len == 1
  doAssert m.files[0].projectId == 111
  doAssert m.files[0].fileId == 200

  m.updateMod(111, 300)
  doAssert m.files.len == 1
  doAssert m.files[0].projectId == 111
  doAssert m.files[0].fileId == 300

  discard m.removeMod(111)
  doAssert m.files.len == 0

block: # manifest write / read from disk
  var m: Manifest
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version

  let dirname = joinPath(".", $rand(1000))
  createDir(dirname)
  defer: removeDir(dirname)
  let mpath = joinPath(dirname, "manifest.json")

  m.writeToDisk(path = mpath)
  let readM = readManifestFromDisk(path = mpath)
  doAssert m == readM

block: # rejectInstalledMod
  var m: Manifest
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version
  m.files = @[ManifestFile(projectId: 1234, fileId: 100)]

  let f = proc(projectId: int): int =
    result = -1
    m.rejectInstalledMod(projectId)
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

  doAssert f() == -1
