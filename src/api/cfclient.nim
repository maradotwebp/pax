## Provides functions for retrieving information about addons and addon files.
## 
## uses the cfcache to reduce the number of requests sent to to the cfapi.

import std/[asyncdispatch, asyncfutures, options, sequtils, sugar, tables]
import cfapi, cfcache, cfcore
export CfApiError

const
  chunkSize = 10 ## how many ids a request should be chunked to.

proc sortTo[T, X](s: seq[T], x: seq[X], pred: proc (x: T): X): seq[T] =
  ## sort `s` so that the order of its items matches `x`.
  ## `pred` should be a function that returns a unique value to which `s` is sorted.
  assert s.len == x.len

  result = newSeq[T]()
  var table = initTable[X, T]()
  for sItem in s:
    table[pred(sItem)] = sItem
  for xItem in x:
    result.add(table[xItem])

proc flatten[T](s: seq[seq[T]]): seq[T] =
  ## flatten `s`.
  result = newSeq[T]()
  for arr in s:
    result = result.concat arr

proc fetchAddonsByQuery*(query: string, category: Option[CfAddonGameCategory]): Future[seq[CfAddon]] {.async.} =
  ## retrieves all addons that match the given `query` search and `category`.
  let data = await cfapi.fetchAddonsByQuery(query, category)
  cfcache.putAddons(data)
  return data

proc fetchAddonsByQuery*(query: string, category: CfAddonGameCategory): Future[seq[CfAddon]] =
  ## retrieves all addons that match the given `query` search and `category`.
  return fetchAddonsByQuery(query, category = some(category))

proc fetchAddonsByQuery*(query: string): Future[seq[CfAddon]] =
  ## retrieves all addons that match the given `query` search.
  return fetchAddonsByQuery(query, category = none[CfAddonGameCategory]())

proc fetchAddon(projectId: int, lookupCache: bool): Future[CfAddon] {.async.} =
  ## get the addon with the given `projectId`.
  if lookupCache:
    withCachedAddon(addon, projectId):
      return addon
  let data = await cfapi.fetchAddon(projectId)
  cfcache.putAddon(data)
  return data

proc fetchAddon*(projectId: int): Future[CfAddon] =
  ## get the addon with the given `projectId`.
  return fetchAddon(projectId, lookupCache = true)

proc fetchAddonsChunks(projectIds: seq[int]): Future[seq[CfAddon]] {.async.} =
  ## get all addons with their given `projectId`.
  if projectIds.len == 0:
    return @[]
  try:
    let data = await cfapi.fetchAddons(projectIds)
    cfcache.putAddons(data)
    return data
  except CfApiError:
    # fallback to looking up the ids individually
    return await all(projectIds.map((x) => fetchAddon(x, lookupCache = false)))

proc fetchAddons*(projectIds: seq[int], chunk = true): Future[seq[CfAddon]] {.async.} =
  ## get all addons with their given `projectId`.
  ## 
  ## chunks the projectIds to minimize request size and to pinpoint errors better.

  # load all addons already in cache
  result = newSeq[CfAddon]()
  var missingIds = newSeq[int]()
  for projectId in projectIds:
    let addon = getAddon(projectId)
    if addon.isSome:
      result.add addon.get()
    else:
      missingIds.add projectId

  if chunk and missingIds.len > chunkSize:
    # if chunking is enabled, chunk the missing ids and fetch the chunks individually
    let futures: seq[Future[seq[CfAddon]]] = collect:
      for chunkedIds in missingIds.distribute(int(missingIds.len / chunkSize), spread = true):
        fetchAddonsChunks(chunkedIds)
    let addons: seq[seq[CfAddon]] = await all(futures)
    result = result.concat(addons.flatten())
  elif missingIds.len > 0:
    # otherwise just fetch them
    result = result.concat(await fetchAddonsChunks(missingIds))

  # check that all addons have been retrieved & fetch missing ones
  if projectIds.len != result.len:
    let currentIds = result.map((x) => x.projectId)
    let missingIds = projectIds.filter((x) => x notin currentIds)
    result = result.concat(await all(missingIds.map((x) => fetchAddon(x, lookupCache = false))))
  # sort so the output is deterministic
  result = result.sortTo(projectIds, (x) => x.projectId)

proc fetchAddon*(slug: string): Future[CfAddon] {.async.} =
  ## get the addon matching the `slug`.
  let data = await cfapi.fetchAddon(slug)
  cfcache.putAddon(data)
  return data

proc fetchAddonFiles*(projectId: int): Future[seq[CfAddonFile]] {.async.} =
  ## get all addon files associated with the given `projectId`.
  let data = await cfapi.fetchAddonFiles(projectId)
  cfcache.putAddonFiles(data)
  return data

proc fetchAddonFilesChunks(fileIds: seq[int], fallback = true): Future[seq[CfAddonFile]] {.async.} =
  ## get all addons with their given `fileIds`.
  if fileIds.len == 0:
    return @[]
  try:
    let data = await cfapi.fetchAddonFiles(fileIds)
    cfcache.putAddonFiles(data)
    return data
  except CfApiError as e:
    # fallback to looking up the ids individually
    if fallback:
      return all(fileIds.map((x) => fetchAddonFilesChunks(@[x], fallback = true))).await.flatten()
    raise newException(CfApiError, e.msg)

proc fetchAddonFiles*(fileIds: seq[int], chunk = true): Future[seq[CfAddonFile]] {.async.} =
  ## get all addon files with their given `fileIds`.
  
  # load all files already in cache
  result = newSeq[CfAddonFile]()
  var missingIds = newSeq[int]()
  for fileId in fileIds:
    let addonFile = getAddonFile(fileId)
    if addonFile.isSome:
      result.add addonFile.get()
    else:
      missingIds.add fileId

  if chunk and missingIds.len > chunkSize:
    # if chunking is enabled, chunk the missing ids and fetch the chunks individually
    let futures: seq[Future[seq[CfAddonFile]]] = collect:
      for chunkedIds in missingIds.distribute(int(missingIds.len / chunkSize), spread = true):
        fetchAddonFilesChunks(chunkedIds)
    let addons: seq[seq[CfAddonFile]] = await all(futures)
    result = result.concat(addons.flatten())
  elif missingIds.len > 0:
    # otherwise just fetch them
    result = result.concat(await fetchAddonFilesChunks(missingIds))

  # check that all addons have been retrieved & fetch missing ones
  if fileIds.len != result.len:
    let currentIds = result.map((x) => x.fileId)
    let missingIds = fileIds.filter((x) => x notin currentIds)
    result = result.concat(all(missingIds.map((x) => fetchAddonFilesChunks(@[x], fallback = false))).await.flatten())
  # sort so the output is deterministic
  result = result.sortTo(fileIds, (x) => x.fileId)

proc fetchAddonFile*(projectId: int, fileId: int): Future[CfAddonFile] {.async.} =
  ## get the addon file with the given `fileId` & `projectId`.
  withCachedAddonFile(addonFile, fileId):
    return addonFile

  let data = await cfapi.fetchAddonFile(projectId, fileId)
  cfcache.putAddonFile(data)
  return data