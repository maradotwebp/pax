## Provides functions for connecting to the CF proxy [https://cfproxy.bmpm.workers.dev].
## 
## The proxy connects to the official API internally, and has capabilities like:
## - Searching for a addon.
## - Retrieving an addon by their project id.
## - Retrieving the files of an given addon.
## 
## Docs for the official API are available at https://docs.curseforge.com.
## Requests to the proxy stay the same, except the base URL is switched out.

import std/[asyncdispatch, json, options, strutils]
import uri except Url
import cfcore, http

const
  ## base url of the cfproxy endpoint
  addonsBaseUrl = "https://cfproxy.bmpm.workers.dev"
  ## base url of the curse metadata api endpoint
  ## used for retrieving mods by their slug, which isn't possible with the curse api
  addonsSlugBaseUrl = "https://curse.nikky.moe/graphql"

type
  CfApiError* = object of HttpRequestError

proc fetchAddonsByQuery*(query: string, category: Option[CfAddonGameCategory]): Future[JsonNode] {.async.} =
  ## retrieves all addons that match the given `query` search and `category`.
  let encodedQuery = encodeUrl(query, usePlus = false)
  var url = addonsBaseUrl & "/v1/mods/search?gameId=432&pageSize=50&sortField=6&sortOrder=desc&searchFilter=" & encodedQuery
  if category.isSome:
    url = url & "&classId=" & $ord(category.get())
  return get(url.Url).await.parseJson["data"]

proc fetchAddon*(projectId: int): Future[JsonNode] {.async.} =
  ## get the addon with the given `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId
  try:
    return get(url.Url).await.parseJson["data"]
  except HttpRequestError:
    raise newException(CfApiError, "addon with project id '" & $projectId & "' not found.")

proc fetchAddons*(projectIds: seq[int]): Future[JsonNode] {.async.} =
  ## get all addons with their given `projectId`.
  let url = addonsBaseUrl & "/v1/mods/"
  let body = %* { "modIds": projectIds }
  try:
    let addons = post(url.Url, $body).await.parseJson["data"]
    if projectIds.len != addons.len:
      raise newException(CfApiError, "one of the addons of project ids '" & $projectIds & "' was not found.")
    return addons
  except HttpRequestError:
    raise newException(CfApiError, "one of the addons of project ids '" & $projectIds & "' was not found.")

proc fetchAddon*(slug: string): Future[JsonNode] {.async.} =
  ## get the addon matching the `slug`.
  let reqBody = %* {
    "query": "{ addons(slug: \"" & slug & "\") { id }}"
  }
  let curseProxyInfo = await post(addonsSlugBaseUrl.Url, body = $reqBody)
  let addons = curseProxyInfo.parseJson["data"]["addons"]
  if addons.len == 0:
    raise newException(CfApiError, "addon with slug '" & slug & "' not found")
  let projectId = addons[0]["id"].getInt()
  return await fetchAddon(projectId)

proc fetchAddonFiles*(projectId: int): Future[JsonNode] {.async.} =
  ## get all addon files associated with the given `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId & "/files?pageSize=10000"
  try:
    return get(url.Url).await.parseJson["data"]
  except HttpRequestError:
    raise newException(CfApiError, "addon with project id '" & $projectId & "' not found.")

proc fetchAddonFiles*(fileIds: seq[int]): Future[JsonNode] {.async.} =
  ## get all addon files with their given `fileIds`.
  let url = addonsBaseUrl & "/v1/mods/files"
  let body = %* { "fileIds": fileIds }
  try:
    let files = post(url.Url, $body).await.parseJson["data"]
    if fileIds.len != files.len:
      raise newException(CfApiError, "one of the addon files of file ids '" & $fileIds & "' was not found.")
    return files
  except HttpRequestError:
    raise newException(CfApiError, "one of the addon files of file ids '" & $fileIds & "' was not found.")

proc fetchAddonFile*(projectId: int, fileId: int): Future[JsonNode] {.async.} =
  ## get the addon file with the given `fileId` & `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId & "/files/" & $fileId
  try:
    return get(url.Url).await.parseJson["data"]
  except HttpRequestError:
    raise newException(CfApiError, "addon with project & file id  '" & $projectId & ':' & $fileId & "' not found.")
