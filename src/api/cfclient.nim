## Provides functions for connecting to the CF proxy [https://cfproxy.bmpm.workers.dev].
## 
## The proxy connects to the official API internally, and has capabilities like:
## - Searching for a addon.
## - Retrieving an addon by their project id.
## - Retrieving the files of an given addon.
## 
## Docs for the official API are available at https://docs.curseforge.com.
## Requests to the proxy stay the same, except the base URL is switched out.

import std/[asyncdispatch, json, options, sequtils, strutils, sugar]
import uri except Url
import cfcore, http

const
  ## base url of the cfproxy endpoint
  addonsBaseUrl = "https://cfproxy.bmpm.workers.dev"
  ## base url of the curse metadata api endpoint
  ## used for retrieving mods by their slug, which isn't possible with the curse api
  addonsSlugBaseUrl = "https://curse.nikky.moe/graphql"

type
  CfClientError* = object of HttpRequestError

proc fetchAddonsByQuery*(query: string, category: Option[CfAddonGameCategory]): Future[seq[CfAddon]] {.async.} =
  ## retrieves all addons that match the given `query` search and `category`.
  let encodedQuery = encodeUrl(query, usePlus = false)
  var url = addonsBaseUrl & "/v1/mods/search?gameId=432&pageSize=50&sortField=6&sortOrder=desc&searchFilter=" & encodedQuery
  if category.isSome:
    url = url & "&classId=" & $ord(category.get())
  return get(url.Url).await.parseJson["data"].addonsFromForgeSvc

proc fetchAddonsByQuery*(query: string, category: CfAddonGameCategory): Future[seq[CfAddon]] =
  ## retrieves all addons that match the given `query` search and `category`.
  return fetchAddonsByQuery(query, category = some(category))

proc fetchAddonsByQuery*(query: string): Future[seq[CfAddon]] =
  ## retrieves all addons that match the given `query` search.
  return fetchAddonsByQuery(query, category = none[CfAddonGameCategory]())

proc fetchAddon*(projectId: int): Future[CfAddon] {.async.} =
  ## get the addon with the given `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId
  try:
    return get(url.Url).await.parseJson["data"].addonFromForgeSvc
  except HttpRequestError:
    raise newException(CfClientError, "addon with project id '" & $projectId & "' not found.")

proc fetchAddons*(projectIds: seq[int], chunk = true): Future[seq[CfAddon]] {.async.} =
  ## get all addons with their given `projectId`.
  ## 
  ## chunks the projectIds to minimize request size and to pinpoint errors better.
  if projectIds.len > 10 and chunk:
    let futures: seq[Future[seq[CfAddon]]] = collect:
      for chunkedIds in projectIds.distribute(int(projectIds.len / 10), spread = true):
        fetchAddons(chunkedIds, chunk = false)
    let addons: seq[seq[CfAddon]] = await all(futures)
    return collect:
      for addonSeq in addons:
        for addon in addonSeq:
          addon
  else:
    let url = addonsBaseUrl & "/v1/mods/"
    let body = %* { "modIds": projectIds }
    try:
      let addons = post(url.Url, $body).await.parseJson["data"].addonsFromForgeSvc
      if addons.len != projectIds.len:
        raise newException(CfClientError, "one of the addons of project ids '" & $projectIds & "' was not found.")
      return addons
    except HttpRequestError:
      let futures: seq[Future[CfAddon]] = collect:
        for projectId in projectIds:
          fetchAddon(projectId)
      return await all(futures)

proc fetchAddon*(slug: string): Future[CfAddon] {.async.} =
  ## get the addon matching the `slug`.
  let reqBody = %* {
    "query": "{ addons(slug: \"" & slug & "\") { id }}"
  }
  let curseProxyInfo = await post(addonsSlugBaseUrl.Url, body = $reqBody)
  let addons = curseProxyInfo.parseJson["data"]["addons"]
  if addons.len == 0:
    raise newException(CfClientError, "addon with slug '" & slug & "' not found")
  let projectId = addons[0]["id"].getInt()
  return await fetchAddon(projectId)

proc fetchAddonFiles*(projectId: int): Future[seq[CfAddonFile]] {.async.} =
  ## get all addon files associated with the given `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId & "/files?pageSize=10000"
  try:
    return get(url.Url).await.parseJson["data"].addonFilesFromForgeSvc
  except HttpRequestError:
    raise newException(CfClientError, "addon with project id '" & $projectId & "' not found.")

proc fetchAddonFiles*(fileIds: seq[int]): Future[seq[CfAddonFile]] {.async.} =
  ## get all addon files with their given `fileIds`.
  let url = addonsBaseUrl & "/v1/mods/files"
  let body = %* { "fileIds": fileIds }
  try:
    let addonFiles = post(url.Url, $body).await.parseJson["data"].addonFilesFromForgeSvc
    if addonFiles.len != fileIds.len:
      raise newException(CfClientError, "one of the addon files of file ids '" & $fileIds & "' was not found.")
    return addonFiles
  except HttpRequestError:
    raise newException(CfClientError, "one of the addon files of file ids '" & $fileIds & "' was not found.")

proc fetchAddonFile*(projectId: int, fileId: int): Future[CfAddonFile] {.async.} =
  ## get the addon file with the given `fileId` & `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId & "/files/" & $fileId
  try:
    return get(url.Url).await.parseJson["data"].addonFileFromForgeSvc
  except HttpRequestError:
    raise newException(CfClientError, "addon with project & file id  '" & $projectId & ':' & $fileId & "' not found.")
