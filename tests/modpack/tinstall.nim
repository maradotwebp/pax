import options, sequtils, sugar
import api/cfcore, modpack/install, modpack/loader, modpack/manifest, modpack/version

block: # InstallStrategy
  doAssert "stable" == InstallStrategy.Stable
  doAssert "recommended" == InstallStrategy.Recommended
  doAssert "newest" == InstallStrategy.Newest
  doAssertRaises(ValueError):
    discard "abcdef".toInstallStrategy

proc initManifest(loader: Loader): Manifest =
  result = Manifest()
  result.name = "testmodpackname"
  result.author = "testmodpackauthor"
  result.version = "1.0.0"
  result.mcModloaderId = $loader & "-0.11.0"

proc initCfAddonFile(fileId: int, name: string, gameVersions: seq[string], releaseType: CfAddonFileReleaseType): CfAddonFile =
  result = CfAddonFile()
  result.fileId = fileId
  result.name = name
  result.releaseType = releaseType
  result.downloadUrl = "https://download-here.com/" & name
  result.gameVersions = gameVersions.map((x) => x.Version)

block: # select out of specified forge mods
  var m = initManifest(loader.Forge)
  let mods = @[
    initCfAddonFile(300, "jei-1.0.2.jar", @["1.16.1", "1.16.2", "Forge"], CfAddonFileReleaseType.Beta),
    initCfAddonFile(200, "jei-1.0.1.jar", @["1.16", "1.16.1", "Forge"], CfAddonFileReleaseType.Release),
    initCfAddonFile(100, "jei-1.0.0.jar", @["1.16", "Forge"], CfAddonFileReleaseType.Alpha)
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

block: # select out of implied forge mods
  var m = initManifest(loader.Forge)
  let mods = @[
    initCfAddonFile(300, "jei-1.0.2.jar", @["1.16.1", "1.16.2"], CfAddonFileReleaseType.Beta),
    initCfAddonFile(200, "jei-1.0.1.jar", @["1.16", "1.16.1", "Forge"], CfAddonFileReleaseType.Alpha),
    initCfAddonFile(100, "jei-FORGE-1.0.0.jar", @["1.16"], CfAddonFileReleaseType.Release)
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[2]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

block: # select out of specified fabric mods
  var m = initManifest(loader.Fabric)
  let mods = @[
    initCfAddonFile(301, "rei-1.0.2.jar", @["1.14.1", "1.14.4", "Fabric"], CfAddonFileReleaseType.Release),
    initCfAddonFile(201, "rei-1.0.1.jar", @["1.14", "1.14.1", "Fabric"], CfAddonFileReleaseType.Release),
    initCfAddonFile(101, "rei-1.0.0.jar", @["1.14", "Fabric"], CfAddonFileReleaseType.Beta)
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.14.4".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

block: # select out of implied fabric mods
  var m = initManifest(loader.Fabric)
  let mods = @[
    initCfAddonFile(301, "rei-1.0.2-fabric.jar", @["1.14.1", "1.14.4"], CfAddonFileReleaseType.Alpha),
    initCfAddonFile(201, "rei-1.0.1-fabric.jar", @["1.14", "1.14.1"], CfAddonFileReleaseType.Beta),
    initCfAddonFile(101, "rei-1.0.0-fabric.jar", @["1.14", "Fabric"], CfAddonFileReleaseType.Release)
  ]

  m.mcVersion = "1.12".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[2]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.14.4".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

block: # select out of mixed mods
  let mods = @[
    initCfAddonFile(801, "abc-1.3.2-fabric.jar", @["1.16.1", "1.16.2"], CfAddonFileReleaseType.Release),
    initCfAddonFile(701, "abc-1.3.2-FORGE.jar", @["1.16.1", "1.16.2"], CfAddonFileReleaseType.Release),
    initCfAddonFile(601, "abc-1.2.2.jar", @["1.16", "1.16.1", "Forge"], CfAddonFileReleaseType.Alpha),
    initCfAddonFile(501, "abc-1.2.1.jar", @["1.16.1", "Fabric"], CfAddonFileReleaseType.Alpha),
    initCfAddonFile(401, "abc-1.2.1.jar", @["1.16", "1.16.1", "Forge"], CfAddonFileReleaseType.Release),
    initCfAddonFile(301, "abc-1.2.0-FABRIC.jar", @["1.16"], CfAddonFileReleaseType.Release),
    initCfAddonFile(201, "abc-1.0.1.jar", @["1.14.4"], CfAddonFileReleaseType.Beta),
    initCfAddonFile(101, "abc-1.0.0.jar", @["1.14", "1.14.1"], CfAddonFileReleaseType.Alpha),
  ]

  # Set loader to forge
  var m = initManifest(loader.Forge)

  m.mcVersion = "1.12".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[7]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[7]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[6]

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[7]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[7]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[6]

  m.mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[4]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[2]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[1]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[1]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[1]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[1]

  # Set loader to forge
  m = initManifest(loader.Fabric)

  m.mcVersion = "1.12".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.14".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.14.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).isNone
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).isNone

  m.mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[5]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[5]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]

  m.mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(m, InstallStrategy.Stable).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Recommended).get() == mods[0]
  doAssert mods.selectAddonFile(m, InstallStrategy.Newest).get() == mods[0]