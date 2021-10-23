import random, os, json
import modpack/manifest, modpack/version

randomize()

block: # manifest write / read from disk
  let m = Manifest()
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version

  let dirname = joinPath(".", $rand(1000))
  createDir(dirname)
  defer: removeDir(dirname)
  let mPath = joinPath(dirname, "manifest.json")

  m.writeToDisk(path = mPath)
  let readM = readManifestFromDisk(path = mPath)
  doAssert m.toJson == readM.toJson