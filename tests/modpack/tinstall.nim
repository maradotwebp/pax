discard """"""

import api/cf, mc/version, modpack/files, modpack/install, modpack/loader, options, sequtils, sugar

block: # InstallStrategy
  doAssert "recommended" == InstallStrategy.recommended
  doAssert "newest" == InstallStrategy.newest
  doAssertRaises(ValueError):
    discard "abcdef".toInstallStrategy

proc initManifest(loader: Loader): Manifest =
  result.name = "testmodpackname"
  result.author = "testmodpackauthor"
  result.version = "1.0.0"
  result.mcModloaderId = $loader & "-0.11.0"

proc initCfModFile(fileId: int, name: string, gameVersions: seq[string]): CfModFile =
  result.fileId = fileId
  result.name = name
  result.downloadUrl = "https://download-here.com/" & name
  result.gameVersions = gameVersions.map((x) => x.Version)

block: # select out of specified forge mods
  var m = initManifest(loader.forge)
  let mods = @[
    initCfModFile(300, "jei-1.0.2.jar", @["1.16.1", "1.16.2", "Forge"]),
    initCfModFile(200, "jei-1.0.1.jar", @["1.16", "1.16.1", "Forge"]),
    initCfModFile(100, "jei-1.0.0.jar", @["1.16", "Forge"])
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.16".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[1]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

block: # select out of implied forge mods
  var m = initManifest(loader.forge)
  let mods = @[
    initCfModFile(300, "jei-1.0.2.jar", @["1.16.1", "1.16.2"]),
    initCfModFile(200, "jei-1.0.1.jar", @["1.16", "1.16.1", "Forge"]),
    initCfModFile(100, "jei-FORGE-1.0.0.jar", @["1.16"])
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.16".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[1]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

block: # select out of specified fabric mods
  var m = initManifest(loader.fabric)
  let mods = @[
    initCfModFile(301, "rei-1.0.2.jar", @["1.14.1", "1.14.4", "Fabric"]),
    initCfModFile(201, "rei-1.0.1.jar", @["1.14", "1.14.1", "Fabric"]),
    initCfModFile(101, "rei-1.0.0.jar", @["1.14", "Fabric"])
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[1]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.14.4".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

block: # select out of implied fabric mods
  var m = initManifest(loader.fabric)
  let mods = @[
    initCfModFile(301, "rei-1.0.2-fabric.jar", @["1.14.1", "1.14.4"]),
    initCfModFile(201, "rei-1.0.1-fabric.jar", @["1.14", "1.14.1"]),
    initCfModFile(101, "rei-1.0.0-fabric.jar", @["1.14", "Fabric"])
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[1]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.14.4".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

block: # select out of mixed mods
  let mods = @[
    initCfModFile(801, "abc-1.3.2-fabric.jar", @["1.16.1", "1.16.2"]),
    initCfModFile(701, "abc-1.3.2-FORGE.jar", @["1.16.1", "1.16.2"]),
    initCfModFile(601, "abc-1.2.2.jar", @["1.16", "1.16.1", "Forge"]),
    initCfModFile(501, "abc-1.2.1.jar", @["1.16.1", "Fabric"]),
    initCfModFile(401, "abc-1.2.1.jar", @["1.16", "1.16.1", "Forge"]),
    initCfModFile(301, "abc-1.2.0-FABRIC.jar", @["1.16"]),
    initCfModFile(201, "abc-1.0.1.jar", @["1.14.4"]),
    initCfModFile(101, "abc-1.0.0.jar", @["1.14", "1.14.1"]),
  ]

  # Set loader to forge
  var m = initManifest(loader.forge)

  m.mcVersion = "1.12".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[7]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[6]

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[7]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[6]

  m.mcVersion = "1.16".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[2]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[1]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[1]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[1]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[1]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[1]

  # Set loader to forge
  m = initManifest(loader.fabric)

  m.mcVersion = "1.12".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).isNone
  doAssert mods.selectModFile(m, InstallStrategy.newest).isNone

  m.mcVersion = "1.16".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[5]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectModFile(m, InstallStrategy.recommended).get() == mods[0]
  doAssert mods.selectModFile(m, InstallStrategy.newest).get() == mods[0]