import sequtils, json

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
    authors*: seq[string]
    downloads*: int
    popularity*: float
    latestFiles*: seq[McModFile]

proc modFileFromJson*(json: JsonNode): McModFile =
  ## creates a mcmodfile object from forgesvc json
  result.fileId = json["id"].getInt()
  result.name = json["displayName"].getStr()
  result.downloadUrl = json["downloadUrl"].getStr()
  result.gameVersions = json["gameVersion"].getElems().map(proc(x: JsonNode): string = x.getStr())

proc modFilesFromJson*(json: JsonNode): seq[McModFile] =
  ## creates a sequence of mcmodfile objects from forgesvc json
  result = json.getElems().map(modFileFromjson)

proc modFromJson*(json: JsonNode, fileId: int): McMod =
  ## creates a mcmod object from forgesvc json
  result.projectId = json["id"].getInt()
  result.name = json["name"].getStr()
  result.description = json["summary"].getStr()
  result.authors = json["authors"].getElems().map(proc(x: JsonNode): string = x["name"].getStr())
  result.downloads = json["downloadCount"].getInt()
  result.popularity = json["popularityScore"].getFloat()
  result.latestFiles = json["latestFiles"].getElems().map(modFileFromJson)