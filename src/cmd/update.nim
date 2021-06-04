import asyncdispatch, json, options
import cmdutils
import ../flow/flow
import ../io/cli, ../io/files, ../io/http
import ../modpack/cf, ../modpack/manifest

proc paxUpdate*(name: string, strategy: string): void =
  ## update an installed mod
  requirePaxProject()

  echoDebug("Loading data from manifest..")
  var project = parseJson(readFile(manifestFile)).projectFromJson
  let search = name.join(" ")

  echoDebug("Searching for mod..")
  let mcMod = project.searchForMod(search, installed=true)

  echo ""
  let file = project.getFile(mcMod.projectId)
  let mcModFile = parseJson(fetch(modFileUrl(file.projectId, file.fileId))).modFileFromJson
  project.displayMod(mcMod, mcModFile)
  echo ""

  returnIfNot promptYN("Are you sure you want to install this mod?", default=true)

  echoDebug("Retrieving mod versions..")
  let modFileContent = waitFor(asyncFetch(modFilesUrl(mcMod.projectId)))
  let mcModFiles = modFileContent.parseJson.modFilesFromJson

  let newMcModFile = project.getModFileToInstall(mcMod, mcModFiles, strategy.installStrategyFromString())
  if newMcModFile.isNone:
    echoError("No compatible version found.")
    quit(1)
  echoInfo("Updating ", fgCyan, mcMod.name, resetStyle, "..")
  project.updateMod(mcMod.projectId, newMcModFile.get().fileId)

  echoDebug("Writing to manifest...")
  writeFile(manifestFile, project.toJson.pretty)