import std/[json, tempfiles, os]
import modpack/[manifest, version]

block: # manifest write / read from disk
  let m = Manifest()
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version

  let tmpdir = createTempDir("", "")
  m.writeToDisk(path = tmpdir)
  let readM = readManifestFromDisk(path = tmpdir)
  doAssert m.toJson == readM.toJson