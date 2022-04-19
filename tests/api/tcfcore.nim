import std/[json, sequtils, sugar]
import api/cfcore
import modpack/version

proc initCfAddonFile(fileId: int, name: string, gameVersions: seq[string], releaseType: CfAddonFileReleaseType): CfAddonFile =
  result = CfAddonFile()
  result.fileId = fileId
  result.name = name
  result.releaseType = releaseType
  result.downloadUrl = "https://download-here.com/" & name
  result.gameVersions = gameVersions.map((x) => x.Version)

proc initCfAddon(projectId: int, name: string, gameVersionLatestFiles: seq[tuple[version: Version, fileId: int]]): CfAddon =
  result = CfAddon()
  result.projectId = projectId
  result.name = name
  result.description = "description"
  result.websiteUrl = "https://website-url.com/" & name
  result.authors = @["user1", "user2"]
  result.downloads = 102039
  result.popularity = 0.5
  result.latestFiles = @[]
  result.gameVersionLatestFiles = gameVersionLatestFiles

block: # AddonFile from/to JSON
  let addonFile = initCfAddonFile(300, "jei-1.0.2.jar", @["1.16.1", "1.16.2", "Forge"], CfAddonFileReleaseType.Beta)

  doAssert addonFile.toJson.addonFileFromForgeSvc.toJson == addonFile.toJson

block: # Addon from/to JSON
  let addon = initCfAddon(200, "Just Enough Items (JEI)", @[(version: "1.16".Version, fileId: 2)])

  doAssert addon.toJson.addonFromForgeSvc.toJson == addon.toJson