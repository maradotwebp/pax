import json, strutils, os
import http, manifest, term
import ../cmd/cmd

const
  projectFolder = "./"
  cacheFolder = joinPath(projectFolder, ".pax/")
  projectFile = joinPath(cacheFolder, ".pax")
  forgeVersionFile = joinPath(cacheFolder, "forge-ver.json")
  packFolder = joinPath(projectFolder, "modpack/")
  overridesFolder = joinPath(packFolder, "overrides/")
  manifestFile = joinPath(packFolder, "manifest.json")

proc createDirIfNotExists(dir: string): void =
  if not existsDir(dir):
    createDir(dir)

proc downloadDBs*: void =
  ## download the necessary db files
  echoInfo "Updating databases.."
  writeFile(forgeVersionFile, downloadForgeVersions())
  echoDebug "Available Forge versions updated."
  discard

proc createCacheFolder*: void =
  ## creates the pax folder (containing cached jsons and project definition)
  echoDebug "Creating cache folder.."
  createDirIfNotExists(cacheFolder)
  writeFile(projectFile, "")
  downloadDBs()

proc createPackFolder*(project: Project): void =
  ## creates the pack folder (containing the actual modpack with the manifest & overrides)
  echoDebug "Creating pack folder.."
  createDirIfNotExists(packFolder)
  createDirIfNotExists(overridesFolder)
  writeFile(manifestFile, createManifest(project))

proc toForgeVer(relationVersion: string): string =
  ## converts a forge version from forge-ver.json ("1.16.4-35.0.0") to a manifest forge version ("forge-35.0.0")
  let split = relationVersion.split("-")
  result = "forge-" & split[1]

proc getForgeVersion*(mcVersion: string): string =
  let json = parseJson(readFile(forgeVersionFile))
  let recommended = json{"by_mcversion", mcVersion, "recommended"}.getStr()
  let latest = json{"by_mcversion", mcVersion, "latest"}.getStr()
  result = if recommended != "":
    recommended.toForgeVer
  elif latest != "":
    latest.toForgeVer
  else:
    ""

proc isPaxProject*: bool =
  ## returns true if the current folder is a pax project folder
  existsFile(projectFile)

template requirePaxProject*: void =
  ## will error if the current folder isn't a pax project
  if not isPaxProject():
    echoError "The current folder isn't a pax project."
    return

template rejectPaxProject*: void =
  ## will error if the current folder is a pax project
  if isPaxProject():
    echoError "The current folder is already a pax project."
    return