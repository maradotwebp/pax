import std/[sequtils, sugar]
import api/cfcore
import modpack/[install, loader, manifest, version]

block: # InstallStrategy
  doAssert "stable".toInstallStrategy == InstallStrategy.Stable
  doAssert "recommended".toInstallStrategy == InstallStrategy.Recommended
  doAssert "newest".toInstallStrategy == InstallStrategy.Newest
  doAssertRaises(ValueError):
    discard "abcdef".toInstallStrategy

proc initCfAddonFile(fileId: int, name: string, gameVersions: seq[string], releaseType: CfAddonFileReleaseType): CfAddonFile =
  result = CfAddonFile()
  result.fileId = fileId
  result.name = name
  result.releaseType = releaseType
  result.downloadUrl = "https://download-here.com/" & name
  result.gameVersions = gameVersions.map((x) => x.Version)

block: # select out of specified forge mods
  let loader = Loader.Forge
  var mcVersion: Version
  let mods = @[
    initCfAddonFile(300, "jei-1.0.2.jar", @["1.16.1", "1.16.2", "Forge"], CfAddonFileReleaseType.Beta),
    initCfAddonFile(200, "jei-1.0.1.jar", @["1.16", "1.16.1", "Forge"], CfAddonFileReleaseType.Release),
    initCfAddonFile(100, "jei-1.0.0.jar", @["1.16", "Forge"], CfAddonFileReleaseType.Alpha)
  ]

  mcVersion = "1.12".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

block: # select out of implied forge mods
  let loader = Loader.Forge
  var mcVersion: Version
  let mods = @[
    initCfAddonFile(300, "jei-1.0.2.jar", @["1.16.1", "1.16.2"], CfAddonFileReleaseType.Beta),
    initCfAddonFile(200, "jei-1.0.1.jar", @["1.16", "1.16.1", "Forge"], CfAddonFileReleaseType.Alpha),
    initCfAddonFile(100, "jei-FORGE-1.0.0.jar", @["1.16"], CfAddonFileReleaseType.Release)
  ]

  mcVersion = "1.12".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[2]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

block: # select out of specified fabric mods
  let loader = Loader.Fabric
  var mcVersion: Version
  let mods = @[
    initCfAddonFile(301, "rei-1.0.2.jar", @["1.14.1", "1.14.4", "Fabric"], CfAddonFileReleaseType.Release),
    initCfAddonFile(201, "rei-1.0.1.jar", @["1.14", "1.14.1", "Fabric"], CfAddonFileReleaseType.Release),
    initCfAddonFile(101, "rei-1.0.0.jar", @["1.14", "Fabric"], CfAddonFileReleaseType.Beta)
  ]

  mcVersion = "1.12".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.14".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.14.1".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.14.4".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

block: # select out of implied fabric mods
  let loader = Loader.Fabric
  var mcVersion: Version
  let mods = @[
    initCfAddonFile(301, "rei-1.0.2-fabric.jar", @["1.14.1", "1.14.4"], CfAddonFileReleaseType.Alpha),
    initCfAddonFile(201, "rei-1.0.1-fabric.jar", @["1.14", "1.14.1"], CfAddonFileReleaseType.Beta),
    initCfAddonFile(101, "rei-1.0.0-fabric.jar", @["1.14", "Fabric"], CfAddonFileReleaseType.Release)
  ]

  mcVersion = "1.12".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.14".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[2]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.14.1".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.14.4".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

block: # select out of mixed mods
  var loader: Loader
  var mcVersion: Version
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
  loader = Loader.Forge

  mcVersion = "1.12".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.14".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[7]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[7]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[6]

  mcVersion = "1.14.1".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[7]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[7]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[6]

  mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[4]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[2]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[1]

  mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[1]

  mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[1]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[1]

  # Set loader to forge
  loader = Loader.Fabric

  mcVersion = "1.12".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.14".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.14.1".Version
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended)
  doAssertRaises(PaxInstallError):
    discard mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest)

  mcVersion = "1.16".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[5]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[5]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.16.1".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

  mcVersion = "1.16.2".Version
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Recommended) == mods[0]
  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Newest) == mods[0]

block: # prevent quilt mods from being selected for forge
  let loader = Loader.Forge
  let mcVersion = "1.16.1".Version
  let mods = @[
    initCfAddonFile(801, "abc-1.3.2.jar", @["Quilt", "1.16.1", "1.16.2"], CfAddonFileReleaseType.Release),
    initCfAddonFile(701, "abc-1.3.2.jar", @["Fabric", "1.16.1", "1.16.2"], CfAddonFileReleaseType.Release),
    initCfAddonFile(601, "abc-1.2.2.jar", @["Forge", "1.16", "1.16.1"], CfAddonFileReleaseType.Alpha),
  ]

  doAssert mods.selectAddonFile(loader, mcVersion, InstallStrategy.Stable) == mods[2]