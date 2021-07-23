import asyncdispatch, json, strutils, uri
import http
import ../modpack/mods

const
  ## base url of the forgesvc endpoint
  modsBaseUrl = "https://addons-ecs.forgesvc.net/api/v2"
  ## base url of the curse metadata api endpoint
  modsSlugBaseUrl = "https://curse.nikky.moe/graphql"

proc fetchModsByQuery*(query: string): Future[seq[McMod]] {.async.} =
  ## search for mods by `query` on the Curseforge API
  const searchUrl = modsBaseUrl & "/addon/search?gameId=432&sectionId=6&pageSize=50"
  let url = searchUrl & "&searchFilter=" & encodeUrl(query, usePlus = false)
  return fetch(url).await.parseJson.modsFromForgeSvc

proc fetchMod*(projectId: int): Future[McMod] {.async.} =
  ## get the mod with the given `projectID` from the Curseforge API
  let url = modsBaseUrl & "/addon/" & $projectId
  return fetch(url).await.parseJson.modFromForgeSvc

proc fetchMod*(slug: string): Future[McMod] {.async.} =
  ## get the mod matching the `slug`
  let reqBody = %* {
    "query": "{ addons(slug: \"" & slug & "\") { id }}"
  }
  let curseProxyInfo = await post(modsSlugBaseUrl, body = $reqBody)
  let projectId = curseProxyInfo.parseJson["data"]["addons"][0]["id"].getInt()
  return await fetchMod(projectId)

proc fetchModFiles*(projectId: int): Future[seq[McModFile]] {.async.} =
  ## get all mod files associated with the given `projectId`
  let url = modsBaseUrl & "/addon/" & $projectId & "/files"
  return fetch(url).await.parseJson.modFilesFromForgeSvc

proc fetchModFile*(projectId: int, fileId: int): Future[McModFile] {.async.} =
  ## get the mod file with the given `fileId`, associated with the given `projectId`
  let url = modsBaseUrl & "/addon/" & $projectId & "/file/" & $fileId
  return fetch(url).await.parseJson.modFileFromForgeSvc
