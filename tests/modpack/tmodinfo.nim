import sequtils, sugar
import api/cfcore, modpack/modinfo, modpack/version

proc initCfAddon(projectId: int, name: string, gameVersionLatestFiles: seq[tuple[version: Version, fileId: int]]): CfAddon =
  result = CfAddon()
  result.projectId = projectId
  result.name = name
  result.gameVersionLatestFiles = gameVersionLatestFiles

proc initCfAddonFile(fileId: int, name: string, gameVersions: seq[string]): CfAddonFile =
  result = CfAddonFile()
  result.fileId = fileId
  result.name = name
  result.downloadUrl = "https://download-here.com/" & name
  result.gameVersions = gameVersions.map((x) => x.Version)

block: # compability
  let file = initCfAddonFile(100, "jei-1.0.0.jar", @["1.16", "1.16.1"])
  
  doAssert file.getCompability("1.12".Version) == Compability.None
  doAssert file.getCompability("1.16".Version) == Compability.Full
  doAssert file.getCompability("1.16.1".Version) == Compability.Full
  doAssert file.getCompability("1.16.2".Version) == Compability.Major
  doAssert file.getCompability("1.17".Version) == Compability.None

block: # freshness
  let mcMod = initCfAddon(200, "Just Enough Items (JEI)", @[
    (version: "1.16".Version, fileId: 2),
    (version: "1.16.1".Version, fileId: 4),
    (version: "1.16.2".Version, fileId: 3),
    (version: "1.16.3".Version, fileId: 4)
  ])

  let fileA = initCfAddonFile(1, "rei-1.1.0.jar", @["1.16", "1.16.1"])

  doAssert fileA.getFreshness("1.12".Version, mcMod) == Freshness.Old
  doAssert fileA.getFreshness("1.16".Version, mcMod) == Freshness.Old
  doAssert fileA.getFreshness("1.16.1".Version, mcMod) == Freshness.Old
  doAssert fileA.getFreshness("1.16.2".Version, mcMod) == Freshness.Old
  doAssert fileA.getFreshness("1.16.3".Version, mcMod) == Freshness.Old

  let fileB = initCfAddonFile(4, "rei-1.1.2.jar", @["1.16", "1.16.1", "1.16.3"])

  doAssert fileB.getFreshness("1.12".Version, mcMod) == Freshness.Old
  doAssert fileB.getFreshness("1.16".Version, mcMod) == Freshness.NewestForAVersion
  doAssert fileB.getFreshness("1.16.1".Version, mcMod) == Freshness.Newest
  doAssert fileB.getFreshness("1.16.2".Version, mcMod) == Freshness.NewestForAVersion
  doAssert fileB.getFreshness("1.16.3".Version, mcMod) == Freshness.Newest

  let fileC = initCfAddonFile(3, "rei-1.1.1.jar", @["1.16", "1.16.2"])

  doAssert fileC.getFreshness("1.12".Version, mcMod) == Freshness.Old
  doAssert fileC.getFreshness("1.16".Version, mcMod) == Freshness.NewestForAVersion
  doAssert fileC.getFreshness("1.16.1".Version, mcMod) == Freshness.NewestForAVersion
  doAssert fileC.getFreshness("1.16.2".Version, mcMod) == Freshness.Newest
  doAssert fileC.getFreshness("1.16.3".Version, mcMod) == Freshness.NewestForAVersion