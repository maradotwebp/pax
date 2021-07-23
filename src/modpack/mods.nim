import json, regex, sequtils, strutils, sugar
import version

type
  McModFileReleaseType* = enum
    ## A mod release type.
    release = 1, beta = 2, alpha = 3

  McModFile* = ref object
    ## A specific version of a curseforge mod.
    fileId*: int
    name*: string
    releaseType*: McModFileReleaseType
    downloadUrl*: string
    gameVersions*: seq[Version]
    dependencies*: seq[int]

  McMod* = ref object
    ## A curseforge mod. Contains multiple versions (McModFile).
    projectId*: int
    name*: string
    description*: string
    websiteUrl*: string
    authors*: seq[string]
    downloads*: int
    popularity*: float
    latestFiles*: seq[McModFile]
    gameVersionLatestFiles*: seq[tuple[version: Version, fileId: int]]

converter modFileFromForgeSvc*(json: JsonNode): McModFile =
  ## creates a mod file from forgesvc json
  result = McModFile()
  result.fileId = json["id"].getInt()
  result.name = json["displayName"].getStr()
  result.releaseType = json["releaseType"].getInt().McModFileReleaseType
  result.downloadUrl = json["downloadUrl"].getStr()
  result.gameVersions = json["gameVersion"].getElems().map((x) => x.getStr().Version)
  result.dependencies = collect(newSeq):
    for depends in json["dependencies"].getElems():
      if depends["type"].getInt() == 3: depends["addonId"].getInt()

converter modFilesFromForgeSvc*(json: JsonNode): seq[McModFile] =
  ## creates mod files from forgesvc json
  return json.getElems().map(modFileFromForgeSvc)

converter modFromForgeSvc*(json: JsonNode): McMod =
  ## creates a mod from forgesvc json
  result = McMod()
  result.projectId = json["id"].getInt()
  result.name = json["name"].getStr()
  result.description = json["summary"].getStr()
  result.websiteUrl = json["websiteUrl"].getStr()
  result.authors = json["authors"].getElems().map((x) => x["name"].getStr())
  result.downloads = json["downloadCount"].getFloat().int
  result.popularity = json["popularityScore"].getFloat()
  result.latestFiles = json["latestFiles"].getElems().map(modFileFromForgeSvc)
  result.gameVersionLatestFiles = newSeq[tuple[version: Version, fileId: int]]()
  for file in json["gameVersionLatestFiles"].getElems():
    let version = file["gameVersion"].getStr().Version
    let fileId = file["projectFileId"].getInt()
    result.gameVersionLatestFiles.add((version: version, fileId: fileId))

converter modsFromForgeSvc*(json: JsonNode): seq[McMod] =
  ## creates mods from forgesvc json
  result = json.getElems().map(modFromForgeSvc)

proc isFabricMod*(file: McModFile): bool =
  ## returns true if `file` is a fabric mod.
  if "Fabric".Version in file.gameVersions:
    return true
  elif file.name.toLower.match(re".*\Wfabric\W.*"):
    return true
  return false

proc isForgeMod*(file: McModFile): bool =
  ## returns true if `file` is a forge mod.
  if file.name.toLower.match(re".*\Wfabric\W.*"):
    return false
  if not ("Fabric".Version in file.gameVersions and not ("Forge".Version in file.gameVersions)):
    return true
  elif file.name.toLower.match(re".*\Wforge\W.*"):
    return true
  return false