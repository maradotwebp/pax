## Caches CF addons & addon files on disk.
## 
## Every time a request for an addon or an addon file is made,
## pax looks up if it already has the corresponding data on disk.
## If yes, no http request is performed (those are expensive and very slow),
## and instead data from the local file system is returned.

import std/[json, options, os, times]

const
  cacheDir* = getCacheDir("pax") ## the cache folder
  addonCacheTime = 30.minutes ## how long an addon is cached
  addonFileCacheTime = 1.days ## how long an addon file is cached

proc getAddonFilename*(projectId: int): string {.inline.} =
  ## get the filename of an addon in the cache.
  return cacheDir / ("addon:" & $projectId)

proc getAddonFileFilename*(fileId: int): string {.inline.} =
  ## get the filename of an addon file in the cache.
  return cacheDir / ("file:" & $fileId)

proc putAddon*(json: JsonNode): void =
  ## put an addon in the cache.
  let projectId = json["id"].getInt()
  let filename = getAddonFilename(projectId)
  try:
    writeFile(filename, $json)
  except IOError:
    discard

proc putAddons*(json: JsonNode): void =
  ## put multiple addons in the cache.
  for elems in json.getElems():
    putAddon(elems)

proc putAddonFile*(json: JsonNode): void =
  ## put an addon file in the cache.
  let fileId = json["id"].getInt()
  let filename = getAddonFileFilename(fileId)
  try:
    writeFile(filename, $json)
  except IOError:
    discard

proc putAddonFiles*(json: JsonNode): void =
  ## put multiple addons in the cache.
  for elems in json.getElems():
    putAddonFile(elems)

proc getAddon*(projectId: int): Option[JsonNode] =
  ## retrieve an addon from cache.
  let filename = getAddonFilename(projectId)
  if not fileExists(filename):
    return none[JsonNode]()
  let info = getFileInfo(filename)
  if info.lastWriteTime + addonCacheTime > getTime():
    let file = try:
      readFile(filename)
    except IOError:
      return none[JsonNode]()
    return some(file.parseJson)
  return none[JsonNode]()

proc getAddonFile*(fileId: int): Option[JsonNode] =
  ## retrieve an addon file from cache.
  let filename = getAddonFileFilename(fileId)
  if not fileExists(filename):
    return none[JsonNode]()
  let info = getFileInfo(filename)
  if info.lastWriteTime + addonFileCacheTime > getTime():
    let file = try:
      readFile(filename)
    except IOError:
      return none[JsonNode]()
    return some(file.parseJson)
  return none[JsonNode]()

proc clean*(): int =
  ## remove old files from the cache.
  ## returns the number of files cleared.
  result = 0
  for filename in walkFiles(cacheDir / "addon:*"):
    let info = getFileInfo(filename)
    if info.lastWriteTime + addonCacheTime < getTime():
      try:
        removeFile(filename)
        inc(result)
      except IOError:
        discard
  for filename in walkFiles(cacheDir / "file:*"):
    let info = getFileInfo(filename)
    if info.lastWriteTime + addonFileCacheTime < getTime():
      try:
        removeFile(filename)
        inc(result)
      except IOError:
        discard

proc purge*(): void =
  ## remove all files from the cache.
  try:
    removeDir(cacheDir)
    createDir(cacheDir)
  except IOError:
    discard

template withCachedAddon*(c: untyped, projectId: int, body: untyped) =
  ## do something with a cached addon.
  let addon = getAddon(projectId)
  if addon.isSome:
    let c: JsonNode = addon.get()
    body

template withCachedAddonFile*(c: untyped, fileId: int, body: untyped) =
  ## do something with a cached addon.
  let addonFile = getAddonFile(fileId)
  if addonFile.isSome:
    let c: JsonNode = addonFile.get()
    body