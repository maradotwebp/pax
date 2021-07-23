discard """"""

import sequtils, sugar
import modpack/modinfo, modpack/mods, modpack/version

proc initMcMod(projectId: int, name: string, gameVersionLatestFiles: seq[tuple[version: Version, fileId: int]]): McMod =
  result = McMod()
  result.projectId = projectId
  result.name = name
  result.gameVersionLatestFiles = gameVersionLatestFiles

proc initMcModFile(fileId: int, name: string, gameVersions: seq[string]): McModFile =
  result = McModFile()
  result.fileId = fileId
  result.name = name
  result.downloadUrl = "https://download-here.com/" & name
  result.gameVersions = gameVersions.map((x) => x.Version)

block: # compability
  let file = initMcModFile(100, "jei-1.0.0.jar", @["1.16", "1.16.1"])
  
  doAssert file.getCompability("1.12".Version) == Compability.none
  doAssert file.getCompability("1.16".Version) == Compability.full
  doAssert file.getCompability("1.16.1".Version) == Compability.full
  doAssert file.getCompability("1.16.2".Version) == Compability.major
  doAssert file.getCompability("1.17".Version) == Compability.none

block: # freshness
  let mcMod = initMcMod(200, "Just Enough Items (JEI)", @[
    (version: "1.16".Version, fileId: 2),
    (version: "1.16.1".Version, fileId: 4),
    (version: "1.16.2".Version, fileId: 3),
    (version: "1.16.3".Version, fileId: 4)
  ])

  let fileA = initMcModFile(1, "rei-1.1.0.jar", @["1.16", "1.16.1"])

  doAssert fileA.getFreshness("1.12".Version, mcMod) == Freshness.old
  doAssert fileA.getFreshness("1.16".Version, mcMod) == Freshness.old
  doAssert fileA.getFreshness("1.16.1".Version, mcMod) == Freshness.old
  doAssert fileA.getFreshness("1.16.2".Version, mcMod) == Freshness.old
  doAssert fileA.getFreshness("1.16.3".Version, mcMod) == Freshness.old

  let fileB = initMcModFile(4, "rei-1.1.2.jar", @["1.16", "1.16.1", "1.16.3"])

  doAssert fileB.getFreshness("1.12".Version, mcMod) == Freshness.old
  doAssert fileB.getFreshness("1.16".Version, mcMod) == Freshness.newestForAVersion
  doAssert fileB.getFreshness("1.16.1".Version, mcMod) == Freshness.newest
  doAssert fileB.getFreshness("1.16.2".Version, mcMod) == Freshness.newestForAVersion
  doAssert fileB.getFreshness("1.16.3".Version, mcMod) == Freshness.newest

  let fileC = initMcModFile(3, "rei-1.1.1.jar", @["1.16", "1.16.2"])

  doAssert fileC.getFreshness("1.12".Version, mcMod) == Freshness.old
  doAssert fileC.getFreshness("1.16".Version, mcMod) == Freshness.newestForAVersion
  doAssert fileC.getFreshness("1.16.1".Version, mcMod) == Freshness.newestForAVersion
  doAssert fileC.getFreshness("1.16.2".Version, mcMod) == Freshness.newest
  doAssert fileC.getFreshness("1.16.3".Version, mcMod) == Freshness.newestForAVersion