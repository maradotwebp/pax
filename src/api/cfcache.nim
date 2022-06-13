## Caches CF addons & addon files on disk.
## 
## Every time a request for an addon or an addon file is made,
## pax looks up if it already has the corresponding data on disk.
## If yes, no http request is performed (those are expensive and very slow),
## and instead data from the local file system is returned.

import std/[json, options, os, times]
import cfcore

const
  addonCacheTime = 30.minutes ## how long an addon is cached
  addonFileCacheTime = 1.days ## how long an addon file is cached

proc getAddonFilename*(projectId: int): string {.inline.} =
  ## get the filename of an addon in the cache.
  return getCacheDir("pax") / ("addon-" & $projectId)

proc getAddonFileFilename*(fileId: int): string {.inline.} =
  ## get the filename of an addon file in the cache.
  return getCacheDir("pax") / ("file-" & $fileId)

proc putAddon*(addon: CfAddon): void =
  ## put an addon in the cache.
  let filename = getAddonFilename(addon.projectId)
  try:
    writeFile(filename, $addon.toJson)
  except IOError:
    discard

proc putAddons*(addons: seq[CfAddon]): void =
  ## put multiple addons in the cache.
  for addon in addons:
    putAddon(addon)

proc putAddonFile*(addonFile: CfAddonFile): void =
  ## put an addon file in the cache.
  let filename = getAddonFileFilename(addonFile.fileId)
  try:
    writeFile(filename, $addonFile.toJson)
  except IOError:
    discard

proc putAddonFiles*(addonFiles: seq[CfAddonFile]): void =
  ## put multiple addons in the cache.
  for addonFile in addonFiles:
    putAddonFile(addonFile)

proc getAddon*(projectId: int): Option[CfAddon] =
  ## retrieve an addon from cache.
  let filename = getAddonFilename(projectId)
  if not fileExists(filename):
    return none[CfAddon]()
  let info = getFileInfo(filename)
  if info.lastWriteTime + addonCacheTime > getTime():
    let file = try:
      readFile(filename)
    except IOError:
      return none[CfAddon]()
    return some(file.parseJson.addonFromForgeSvc)
  return none[CfAddon]()

proc getAddonFile*(fileId: int): Option[CfAddonFile] =
  ## retrieve an addon file from cache.
  let filename = getAddonFileFilename(fileId)
  if not fileExists(filename):
    return none[CfAddonFile]()
  let info = getFileInfo(filename)
  if info.lastWriteTime + addonFileCacheTime > getTime():
    let file = try:
      readFile(filename)
    except IOError:
      return none[CfAddonFile]()
    return some(file.parseJson.addonFileFromForgeSvc)
  return none[CfAddonFile]()

proc clean*(): int =
  ## remove old files from the cache.
  ## returns the number of files cleared.
  result = 0
  for filename in walkFiles(getCacheDir("pax") / "addon:*"):
    let info = getFileInfo(filename)
    if info.lastWriteTime + addonCacheTime < getTime():
      try:
        removeFile(filename)
        inc(result)
      except IOError:
        discard
  for filename in walkFiles(getCacheDir("pax") / "file:*"):
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
    removeDir(getCacheDir("pax"))
    createDir(getCacheDir("pax"))
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
