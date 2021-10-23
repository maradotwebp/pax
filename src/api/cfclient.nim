## Provides functions for connecting to the unofficial curseforge api.
## 
## The unofficial API has capabilities like:
## - Searching for a addon.
## - Retrieving an addon by their project id.
## - Retrieving the files of an given addon.
## 
## Some docs for the unofficial API are available at https://gaz492.github.io/.

import asyncdispatch, json, options, strutils
import uri except Url
import cfcore, http

const
  ## base url of the forgesvc endpoint
  addonsBaseUrl = "https://addons-ecs.forgesvc.net/api/v2"
  ## base url of the curse metadata api endpoint
  ## used for retrieving mods by their slug, which isn't possible with the curse api
  addonsSlugBaseUrl = "https://curse.nikky.moe/graphql"

proc fetchAddonsByQuery*(query: string, category = CfAddonGameCategory.Mod): Future[seq[CfAddon]] {.async.} =
  ## retrieves all addons that match the given `query` search and `category`.
  let encodedQuery = encodeUrl(query, usePlus = false)
  let url = addonsBaseUrl & "/addon/search?gameId=432&sectionId=" & $category & "&pageSize=50&searchFilter=" & encodedQuery
  try:
    return get(url.Url).await.parseJson.addonsFromForgeSvc
  except HttpRequestError:
    return @[]

proc fetchAddon*(projectId: int): Future[Option[CfAddon]] {.async.} =
  ## get the addon with the given `projectId`.
  let url = addonsBaseUrl & "/addon/" & $projectId
  try:
    return get(url.Url).await.parseJson.addonFromForgeSvc.some
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
  let url = addonsBaseUrl & "/addon/" & $projectId & "/files"
  try:
    return get(url.Url).await.parseJson.addonFilesFromForgeSvc
  except HttpRequestError:
    return @[]

proc fetchAddonFile*(projectId: int, fileId: int): Future[Option[CfAddonFile]] {.async.} =
  ## get the addon file with the given `fileId` & `projectId`.
  let url = addonsBaseUrl & "/addon/" & $projectId & "/file/" & $fileId
  try:
    return get(url.Url).await.parseJson.addonFileFromForgeSvc.some
  except HttpRequestError:
    return none[CfAddonFile]()
