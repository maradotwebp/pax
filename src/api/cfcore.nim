## Provides the types returned by the Curseforge API.
## 
## Curseforge has two main entities:
## - Addons (https://docs.curseforge.com/#search-mods),
##   which are modifications to the source game in one way or another.
##   For Minecraft, mods are one type of CF addon, resourcepacks are another.
## - Addon files (https://docs.curseforge.com/#curseforge-core-api-files),
##   which are files attached to an addon and can be seen as versions of an addon.

import std/[json, sequtils, strutils, sugar]
import regex
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

converter toJson*(file: CfAddonFile): JsonNode =
  ## creates json from an addon file
  result = %* {
    "id": file.fileId,
    "displayName": file.name,
    "releaseType": file.releaseType.ord,
    "downloadUrl": file.downloadUrl,
    "gameVersions": file.gameVersions.map((x) => $x),
    "dependencies": file.dependencies.map((x) => %* {
      "relationType": RequiredDependencyType,
      "modId": x
    })
  }

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

converter toJson*(addon: CfAddon): JsonNode =
  result = %* {
    "id": addon.projectId,
    "name": addon.name,
    "summary": addon.description,
    "links": {
      "websiteUrl": addon.websiteUrl
    },
    "authors": addon.authors.map((x) => %* {
      "name": x
    }),
    "downloadCount": addon.downloads,
    "gamePopularityRank": addon.popularity,
    "latestFiles": addon.latestFiles.map((x) => x.toJson()),
    "latestFilesIndexes": addon.gameVersionLatestFiles.map((x) => %* {
      "gameVersion": x.version.`$`,
      "fileId": x.fileId
    })
  }

proc isFabricCompatible*(file: CfAddonFile): bool =
  ## returns true if `file` is compatible with the fabric loader.
  if "Fabric".Version in file.gameVersions:
    return true
  if file.name.toLower.match(re2".*\Wfabric\W.*"):
    return true
  return false

proc isQuiltCompatible*(file: CfAddonFile): bool =
  ## returns true if `file` is compatible with the quilt loader.
  if "Quilt".Version in file.gameVersions:
    return true
  if file.name.toLower.match(re2".*\Wquilt\W.*"):
    return true
  if isFabricCompatible(file):
    return true
  return false

proc isForgeCompatible*(file: CfAddonFile): bool =
  ## returns true if `file` is compatible with the forge loader.
  if file.name.toLower.match(re2".*\Wquilt\W.*") or file.name.toLower.match(re2".*\Wfabric\W.*"):
    return false
  if "Forge".Version in file.gameVersions or not ("Fabric".Version in file.gameVersions or "Quilt".Version in file.gameVersions):
    return true
  if file.name.toLower.match(re2".*\Wforge\W.*"):
    return true
  return false