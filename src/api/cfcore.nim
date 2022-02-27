## Provides the types returned by the `cfclient` module.
## 
## Curseforge has two main entities:
## - Addons, which are modifications to the source game in one way or another.
##   In Minecraft, mods are one type of CF addon, resourcepacks are another.
## - Addon files, which are files attached to one addon and can be seen of versions of an addon.

import json, regex, sequtils, strutils, sugar
import ../modpack/version

type
  CfAddonFileReleaseType* = enum
    ## Release type of an addon.
    Release = 1, Beta = 2, Alpha = 3

  CfAddonFile* = ref object
    ## A file that belongs to an addon.
    fileId*: int
    name*: string
    releaseType*: CfAddonFileReleaseType
    downloadUrl*: string
    gameVersions*: seq[Version]
    dependencies*: seq[int]

  CfAddonGameCategory* = enum
    ## Type of an addon.
    Mod = 6, Resourcepack = 12

  CfAddon* = ref object
    ## A curseforge addon.
    projectId*: int
    name*: string
    description*: string
    websiteUrl*: string
    authors*: seq[string]
    downloads*: int
    popularity*: float
    latestFiles*: seq[CfAddonFile]
    gameVersionLatestFiles*: seq[tuple[version: Version, fileId: int]]

const
  ## the type of a required addon dependency.
  RequiredDependencyType = 3

converter addonFileFromForgeSvc*(json: JsonNode): CfAddonFile =
  ## creates an addon file from json retrieved by an forgesvc endpoint
  result = CfAddonFile()
  result.fileId = json["id"].getInt()
  result.name = json["displayName"].getStr()
  result.releaseType = json["releaseType"].getInt().CfAddonFileReleaseType
  result.downloadUrl = json["downloadUrl"].getStr()
  result.gameVersions = json["gameVersions"].getElems().map((x) => x.getStr().Version)
  result.dependencies = collect(newSeq):
    for depends in json["dependencies"].getElems():
      if depends["relationType"].getInt() == RequiredDependencyType:
        depends["modId"].getInt()

converter addonFilesFromForgeSvc*(json: JsonNode): seq[CfAddonFile] =
  ## creates addon files from json retrieved by an forgesvc endpoint
  return json.getElems().map(addonFileFromForgeSvc)

converter addonFromForgeSvc*(json: JsonNode): CfAddon =
  ## creates an addon from json retrieved by an forgesvc endpoint
  result = CfAddon()
  result.projectId = json["id"].getInt()
  result.name = json["name"].getStr()
  result.description = json["summary"].getStr()
  result.websiteUrl = json["links"]{"websiteUrl"}.getStr()
  result.authors = json["authors"].getElems().map((x) => x["name"].getStr())
  result.downloads = json["downloadCount"].getFloat().int
  result.popularity = json["gamePopularityRank"].getFloat()
  result.latestFiles = json["latestFiles"].getElems().map(addonFileFromForgeSvc)
  result.gameVersionLatestFiles = collect(newSeq):
    for file in json["latestFilesIndexes"].getElems():
      let version = file["gameVersion"].getStr().Version
      let fileId = file["fileId"].getInt()
      (version: version, fileId: fileId)

converter addonsFromForgeSvc*(json: JsonNode): seq[CfAddon] =
  ## creates addons from json retrieved by an forgesvc endpoint
  result = json.getElems().map(addonFromForgeSvc)

proc isFabricCompatible*(file: CfAddonFile): bool =
  ## returns true if `file` is compatible with the fabric loader.
  if "Fabric".Version in file.gameVersions:
    return true
  if file.name.toLower.match(re".*\Wfabric\W.*"):
    return true
  return false

proc isForgeCompatible*(file: CfAddonFile): bool =
  ## returns true if `file` is compatible with the forge loader.
  if file.name.toLower.match(re".*\Wfabric\W.*"):
    return false
  if not ("Fabric".Version in file.gameVersions and not ("Forge".Version in file.gameVersions)):
    return true
  if file.name.toLower.match(re".*\Wforge\W.*"):
    return true
  return false