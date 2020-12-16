import sequtils, tables, json

type
  McModFile* = object
    ## A specific version of a curseforge mod.
    fileId*: int
    name*: string
    downloadUrl*: string
    gameVersions*: seq[string]

  McMod* = object
    ## A curseforge mod. Contains multiple versions (McModFile).
    projectId*: int
    name*: string
    description*: string
    websiteUrl*: string
    authors*: seq[string]
    downloads*: int
    popularity*: float
    latestFiles*: seq[McModFile]
    gameVersionLatestFiles*: Table[string, int]

proc modFileFromJson*(json: JsonNode): McModFile =
  ## creates a mcmodfile object from forgesvc json
  result.fileId = json["id"].getInt()
  result.name = json["displayName"].getStr()
  result.downloadUrl = json["downloadUrl"].getStr()
  result.gameVersions = json["gameVersion"].getElems().map(proc(x: JsonNode): string = x.getStr())

proc modFilesFromJson*(json: JsonNode): seq[McModFile] =
  ## creates a sequence of mcmodfile objects from forgesvc json
  result = json.getElems().map(modFileFromjson)

proc modFromJson*(json: JsonNode): McMod =
  ## creates a mcmod object from forgesvc json
  result.projectId = json["id"].getInt()
  result.name = json["name"].getStr()
  result.description = json["summary"].getStr()
  result.websiteUrl = json["websiteUrl"].getStr()
  result.authors = json["authors"].getElems().map(proc(x: JsonNode): string = x["name"].getStr())
  result.downloads = int(json["downloadCount"].getFloat())
  result.popularity = json["popularityScore"].getFloat()
  result.latestFiles = json["latestFiles"].getElems().map(modFileFromJson)
  var gameVersionLatestFiles = initTable[string, int]()
  for file in json["gameVersionLatestFiles"].getElems():
    let version = file["gameVersion"].getStr()
    let fileId = file["projectFileId"].getInt()
    gameVersionLatestFiles[version] = fileId
  result.gameVersionLatestFiles = gameVersionLatestFiles

proc modsFromJson*(json: JsonNode): seq[McMod] =
  ## creates a sequence of mcmod objects from forgesvc json
  result = json.getElems().map(modFromjson)