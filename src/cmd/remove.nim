import json
import cmdutils
import ../flow/flow
import ../io/cli, ../io/files, ../io/http
import ../modpack/cf, ../modpack/manifest

proc paxRemove*(name: string): void =
  ## remove an installed mod
  requirePaxProject()

  echoDebug("Loading data from manifest..")
  var project = parseJson(readFile(manifestFile)).projectFromJson

  echoDebug("Searching for mod..")
  let mcMod = project.searchForMod(name, installed=true)

  echo ""
  let file = project.getFile(mcMod.projectId)
  let mcModFile = parseJson(fetch(modFileUrl(file.projectId, file.fileId))).modFileFromJson
  project.displayMod(mcMod, mcModFile)
  echo ""

  returnIfNot promptYN("Are you sure you want to remove this mod?", default=true)
  
  echoInfo("Removing ", fgCyan, mcMod.name, resetStyle, "..")
  project.removeMod(mcMod.projectId)

  echoDebug("Writing to manifest...")
  writeFile(manifestFile, project.toJson.pretty)
