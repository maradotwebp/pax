## Provides functions for connecting to the CF proxy [https://github.com/bmpm-mc/cfproxy].
## 
## The proxy connects to the official API internally, and has capabilities like:
## - Searching for a addon.
## - Retrieving an addon by their project id.
## - Retrieving the files of an given addon.
## 
## Docs for the official API are available at https://docs.curseforge.com.
## Requests to the proxy stay the same, except the base URL is switched out.

import asyncdispatch, json, options, strutils
import uri except Url
import cfcore, http

const
  ## base url of the cfproxy endpoint
  addonsBaseUrl = "https://cfproxy.fly.dev"
  ## base url of the curse metadata api endpoint
  ## used for retrieving mods by their slug, which isn't possible with the curse api
  addonsSlugBaseUrl = "https://curse.nikky.moe/graphql"

proc fetchAddonsByQuery*(query: string, category: Option[CfAddonGameCategory]): Future[seq[CfAddon]] {.async.} =
  ## retrieves all addons that match the given `query` search and `category`.
  let encodedQuery = encodeUrl(query, usePlus = false)
  var url = addonsBaseUrl & "/v1/mods/search?gameId=432&pageSize=50&sortField=6&sortOrder=desc&searchFilter=" & encodedQuery
  if category.isSome:
    url = url & "&classId=" & $ord(category.get())
  try:
    return get(url.Url).await.parseJson["data"].addonsFromForgeSvc
  except HttpRequestError:
    return @[]

proc fetchAddonsByQuery*(query: string): Future[seq[CfAddon]] {.async.} =
  return await fetchAddonsByQuery(query, category = none[CfAddonGameCategory]())

proc fetchAddon*(projectId: int): Future[Option[CfAddon]] {.async.} =
  ## get the addon with the given `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId
  try:
    return get(url.Url).await.parseJson["data"].addonFromForgeSvc.some
  except HttpRequestError:
    return none[CfAddon]()

proc fetchAddon*(slug: string): Future[Option[CfAddon]] {.async.} =
  ## get the addon matching the `slug`.
  let reqBody = %* {
    "query": "{ addons(slug: \"" & slug & "\") { id }}"
  }
  let curseProxyInfo = await post(addonsSlugBaseUrl.Url, body = $reqBody)
  var projectId: int
  try:
    let addons = curseProxyInfo.parseJson["data"]["addons"]
    if addons.len == 0:
      return none[CfAddon]()
    projectId = addons[0]["id"].getInt()
  except KeyError:
    return none[CfAddon]()
  return await fetchAddon(projectId)

proc fetchAddonFiles*(projectId: int): Future[seq[CfAddonFile]] {.async.} =
  ## get all addon files associated with the given `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId & "/files?pageSize=10000"
  try:
    return get(url.Url).await.parseJson["data"].addonFilesFromForgeSvc
  except HttpRequestError:
    return @[]

proc fetchAddonFile*(projectId: int, fileId: int): Future[Option[CfAddonFile]] {.async.} =
  ## get the addon file with the given `fileId` & `projectId`.
  let url = addonsBaseUrl & "/v1/mods/" & $projectId & "/files/" & $fileId
  try:
    return get(url.Url).await.parseJson["data"].addonFileFromForgeSvc.some
  except HttpRequestError:
    return none[CfAddonFile]()
