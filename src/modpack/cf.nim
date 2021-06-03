import json, sequtils, sugar, tables, terminal, version

type
  CfModFile* = object
    ## A specific version of a curseforge mod.
    fileId*: int
    name*: string
    downloadUrl*: string
    gameVersions*: seq[Version]

  CfMod* = object
    ## A curseforge mod. Contains multiple versions (McModFile).
    projectId*: int
    name*: string
    description*: string
    websiteUrl*: string
    authors*: seq[string]
    downloads*: int
    popularity*: float
    latestFiles*: seq[CfModFile]
    gameVersionLatestFiles*: seq[tuple[version: Version, fileId: int]]

  Compability* = enum
    ## compability of a mod version with the modpack version
    ## none = will not be compatible
    ## major = mod major version matches modpack major version, probably compatible
    ## full = mod version exactly matches modpack version, fully compatible
    none, major, full

  Freshness* = enum
    ## if an update to the currently installed version is available
    ## old = file is not the latest version for all gameversions
    ## newestForAVersion = file is the latest version for a gameversion
    ## newest = file is the newest version for the current modpack version
    old, newestForAVersion, newest

const
  ## icon for compability
  compabilityIcon* = "•"
  ## icon for freshness
  freshnessIcon* = "↑"

proc modFileFromJson*(json: JsonNode): CfModFile =
  ## creates a mcmodfile object from forgesvc json
  result.fileId = json["id"].getInt()
  result.name = json["displayName"].getStr()
  result.downloadUrl = json["downloadUrl"].getStr()
  result.gameVersions = json["gameVersion"].getElems().map(proc(x: JsonNode): Version = x.getStr().Version)

proc modFilesFromJson*(json: JsonNode): seq[CfModFile] =
  ## creates a sequence of mcmodfile objects from forgesvc json
  result = json.getElems().map(modFileFromJson)

proc modFromJson*(json: JsonNode): CfMod =
  ## creates a mcmod object from forgesvc json
  result.projectId = json["id"].getInt()
  result.name = json["name"].getStr()
  result.description = json["summary"].getStr()
  result.websiteUrl = json["websiteUrl"].getStr()
  result.authors = json["authors"].getElems().map(proc(x: JsonNode): string = x["name"].getStr())
  result.downloads = int(json["downloadCount"].getFloat())
  result.popularity = json["popularityScore"].getFloat()
  result.latestFiles = json["latestFiles"].getElems().map(modFileFromJson)
  var gameVersionLatestFiles = newSeq[tuple[version: Version, fileId: int]]()
  for file in json["gameVersionLatestFiles"].getElems():
    let version = file["gameVersion"].getStr().Version
    let fileId = file["projectFileId"].getInt()
    gameVersionLatestFiles.add((version: version, fileId: fileId))
  result.gameVersionLatestFiles = gameVersionLatestFiles

proc modsFromJson*(json: JsonNode): seq[CfMod] =
  ## creates a sequence of mcmod objects from forgesvc json
  result = json.getElems().map(modFromjson)

proc getFileCompability*(modpackVersion: Version, file: CfModFile): Compability =
  ## get compability of a file
  if modpackVersion in file.gameVersions: return Compability.full
  if modpackVersion.minor in file.gameVersions.properVersions.map(minor): return Compability.major
  return Compability.none

proc getColor*(c: Compability): ForegroundColor =
  ## get the color for a compability
  case c:
    of Compability.full: fgGreen
    of Compability.major: fgYellow
    of Compability.none: fgRed

proc getMessage*(c: Compability): string =
  ## get the message for a certain compability
  case c:
    of Compability.full: "The installed mod is compatible with the modpack's minecraft version."
    of Compability.major: "The installed mod only matches the major version as the modpack. Issues may arise."
    of Compability.none: "The installed mod is incompatible with the modpack's minecraft version."

proc getFileFreshness*(modpackVersion: Version, file: CfModFile, mcMod: CfMod): Freshness =
  ## get freshness of a file
  let versionFiles = mcMod.gameVersionLatestFiles
  if versionFiles.filter((x) => x.version == modpackVersion and x.fileId == file.fileId).len > 0: return Freshness.newest
  for versionFile in versionFiles:
    if file.fileId == versionFile.fileId:
      if any(file.gameVersions.properVersions, (it) => it > modpackVersion):
        return Freshness.newestForAVersion
      else:
        return Freshness.newest
  return Freshness.old

proc getColor*(f: Freshness): ForegroundColor =
  ## get the color for a freshness
  case f:
    of Freshness.newest: fgGreen
    of Freshness.newestForAVersion: fgYellow
    of Freshness.old: fgRed

proc getMessage*(f: Freshness): string =
  ## get the message for a certain freshness
  case f:
    of Freshness.newest: "No mod updates available."
    of Freshness.newestForAVersion: "Your installed version is newer than the recommended version. Issues may arise."
    of Freshness.old: "There is a newer version of this mod available."

proc isLatestFileForVersion*(file: CfModFile, version: string, gameVersionLatestFiles: Table[string, int]): bool =
  ## returns true if file is the latest available version for that gameversion
  return gameVersionLatestFiles[version] == file.fileId