import asyncdispatch, json, options
import cmdutils
import ../flow/flow
import ../io/cli, ../io/files, ../io/http
import ../modpack/cf, ../modpack/manifest

proc paxAdd*(name: string, strategy: string): void =
  ## add a new mod
  requirePaxProject()

  echoDebug("Loading data from manifest..")
  var project = parseJson(readFile(manifestFile)).projectFromJson

  echoDebug("Searching for mod..")
  let mcMod = project.searchForMod(name, installed=false)

  echo ""
  project.displayMod(mcMod)
  echo ""

  returnIfNot promptYN("Are you sure you want to install this mod?", default=true)

  echoDebug("Retrieving mod versions..")
  let modFileContent = waitFor(asyncFetch(modFilesUrl(mcMod.projectId)))
  let mcModFiles = modFileContent.parseJson.modFilesFromJson

  let mcModFile = project.getModFileToInstall(mcMod, mcModFiles, installStrategyFromString(strategy))
  if mcModFile.isNone:
    echoError "No compatible version found."
    quit(1)
  echoInfo("Installing ", fgCyan, mcMod.name, resetStyle, "..")
  project.installMod(mcMod.projectId, mcModFile.get().fileId)

  echoDebug "Writing to manifest..."
  writeFile(manifestFile, project.toJson.pretty)
