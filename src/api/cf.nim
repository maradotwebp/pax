import asyncdispatch, json, sequtils, sugar, uri
import http
import ../mc/version

type
  CfModFile* = object
    ## A specific version of a curseforge mod.
    fileId*: int
    name*: string
    downloadUrl*: string
    gameVersions*: seq[Version]

  CfMod* = object
    ## A curseforge mod. Contains multiple versions (CfModFile).
    projectId*: int
    name*: string
    description*: string
    websiteUrl*: string
    authors*: seq[string]
    downloads*: int
    popularity*: float
    latestFiles*: seq[CfModFile]
    gameVersionLatestFiles*: seq[tuple[version: Version, fileId: int]]

const
  ## base url of the forgesvc endpoint
  modsBaseUrl = "https://addons-ecs.forgesvc.net/api/v2"

converter toCfModFile(json: JsonNode): CfModFile =
  ## creates a CfModFile from forgesvc json
  result.fileId = json["id"].getInt()
  result.name = json["displayName"].getStr()
  result.downloadUrl = json["downloadUrl"].getStr()
  result.gameVersions = json["gameVersion"].getElems().map((x) => x.getStr().Version)

converter toCfModFiles(json: JsonNode): seq[CfModFile] =
  ## creates a seq of CfModFiles from forgesvc json
  return json.getElems().map(toCfModFile)

converter toCfMod(json: JsonNode): CfMod =
  ## creates a mcmod object from forgesvc json
  result.projectId = json["id"].getInt()
  result.name = json["name"].getStr()
  result.description = json["summary"].getStr()
  result.websiteUrl = json["websiteUrl"].getStr()
  result.authors = json["authors"].getElems().map((x) => x["name"].getStr())
  result.downloads = json["downloadCount"].getFloat().int
  result.popularity = json["popularityScore"].getFloat()
  result.latestFiles = json["latestFiles"].getElems().map(toCfModFile)
  result.gameVersionLatestFiles = newSeq[tuple[version: Version, fileId: int]]()
  for file in json["gameVersionLatestFiles"].getElems():
    let version = file["gameVersion"].getStr().Version
    let fileId = file["projectFileId"].getInt()
    result.gameVersionLatestFiles.add((version: version, fileId: fileId))

converter toCfMods(json: JsonNode): seq[CfMod] =
  ## creates a sequence of mcmod objects from forgesvc json
  result = json.getElems().map(toCfMod)

proc fetchModsByQuery*(query: string): Future[seq[CfMod]] {.async.} =
  ## search for CfMods by `query` on the Curseforge API
  const searchUrl = modsBaseUrl & "/addon/search?gameId=432&sectionId=6&pageSize=100"
  let url = searchUrl & "&searchFilter=" & encodeUrl(query, usePlus=false)
  return fetch(url).await.parseJson.toCfMods

proc fetchMod*(projectId: int): Future[CfMod] {.async.} =
  ## get the CfMod with the given `projectID` from the Curseforge API
  let url = modsBaseUrl & "/addon/" & $projectId
  return fetch(url).await.parseJson.toCfMod

proc fetchModFiles*(projectId: int): Future[seq[CfModFile]] {.async.} =
  ## get all mod files associated with the given `projectId`
  let url = modsBaseUrl & "/addon/" & $projectId & "/files"
  return fetch(url).await.parseJson.toCfModFiles

proc fetchModFile*(projectId: int, fileId: int): Future[CfModFile] {.async.} =
  ## get the mod file with the given `fileId`, associated with the given `projectId`
  let url = modsBaseUrl & "/addon/" & $projectId & "/file/" & $fileId
  return fetch(url).await.parseJson.toCfModFile