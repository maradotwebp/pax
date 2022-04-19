import std/[options, sequtils, sugar]
import api/[cfcache, cfcore]
import modpack/version

cfcache.purge()

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

block: # caching addons
  let addon = initCfAddon(123, "Just Enough Items (JEI)", @[(version: "1.16".Version, fileId: 2)])
  doAssert getAddon(123).isNone()
  cfcache.putAddon(addon)
  doAssert getAddon(123).isSome()

block: # caching addon files
  let addonFile = initCfAddonFile(456, "jei-1.0.2.jar", @["1.16.1", "1.16.2", "Forge"], CfAddonFileReleaseType.Beta)
  doAssert getAddonFile(456).isNone()
  cfcache.putAddonFile(addonFile)
  doAssert getAddonFile(456).isSome()

block: # cleaning
  let numCleanedFiles = cfcache.clean()
  doAssert numCleanedFiles == 0