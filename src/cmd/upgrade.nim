import asyncdispatch, asyncfutures, json, sequtils, options
import cmdutils
import ../flow/flow
import ../io/cli, ../io/files, ../io/http
import ../modpack/cf, ../modpack/manifest

proc paxUpgrade*(strategy: string): void =
  ## update all installed mods
  requirePaxProject()

  echoDebug("Loading data from manifest..")
  var project = parseJson(readFile(manifestFile)).projectFromJson
  let fileCount = project.files.len
  let allModRequests = project.files.map(proc(file: ManifestFile): Future[CfMod] {.async.} =
    return (await asyncFetch(modUrl(file.projectId))).parseJson.modFromJson
  )

  echoInfo("Loading mods..")
  let mods = waitFor(all(allModRequests))

  returnIfNot promptYN($fileCount & " mods will be updated to the " & $strategy & " version. Do you want to continue?", default=true)

  for mcMod in mods:
    let mcModFile = project.getModFileToInstall(mcMod, strategy.installStrategyFromString())
    if mcModFile.isNone:
      echoWarn(fgCyan, mcMod.name, resetStyle, " does not have a compatible version. Skipping..")
      continue
    echoInfo("Updating ", fgCyan, mcMod.name, resetStyle, "..")
    project.updateMod(mcMod.projectId, mcModFile.get().fileId)

  echoDebug("Writing to manifest...")
  writeFile(manifestFile, project.toJson.pretty)