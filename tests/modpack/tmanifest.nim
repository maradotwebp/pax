import modpack/[loader, manifest, version]

block: # manifest loader
  let m = Manifest()
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version

  m.mcModloaderId = "fabric-0.11.0"
  doAssert m.loader == Loader.Fabric

  m.mcModloaderId = "forge-34.1.0"
  doAssert m.loader == Loader.Forge

let file = initManifestFile(
  projectId = 111,
  fileId = 200,
  initManifestMetadata(
    name = "test",
    explicit = true,
    pinned = false,
    dependencies = @[]
  )
)

block: # manifest mods
  var m = Manifest()
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version

  doAssert m.files.len == 0

  block: # install
    m.installAddon(file)
    doAssert m.files.len == 1
    doAssert m.files[0].projectId == 111
    doAssert m.files[0].fileId == 200

  block: # update with project & file id
    m.updateAddon(111, 300)
    doAssert m.files.len == 1
    doAssert m.files[0].projectId == 111
    doAssert m.files[0].fileId == 300

  block: # update with file
    m.updateAddon(file)
    doAssert m.files.len == 1
    doAssert m.files[0].projectId == 111
    doAssert m.files[0].fileId == 300

  block: # remove
    discard m.removeAddon(111)
    doAssert m.files.len == 0
