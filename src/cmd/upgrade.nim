import asyncdispatch, asyncfutures, sequtils, strutils, sugar, options, os
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/manifest, ../modpack/install
import ../util/flow

proc paxUpgrade*(strategy: string): void =
  ## update all installed mods
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()
  let fileCount = manifest.files.len

  returnIfNot promptYN($fileCount & " mods will be updated to the " & $strategy & " version. Do you want to continue?", default = true)

  let mcModRequests = manifest.files.map((x) => fetchMod(x.projectId))
  let mcModFilesRequests = manifest.files.map((x) => fetchModFiles(x.projectId))
  let mcMods = all(mcModRequests)
  let mcModFiles = all(mcModFilesRequests)

  echoInfo "Loading mods.."
  waitFor(mcMods and mcModFiles)
  var modData = zip(mcMods.read(), mcModFiles.read())

  for pairs in modData:
    let (mcMod, mcModFiles) = pairs
    let mcModFile = mcModFiles.selectModFile(manifest, strategy)
    if mcModFile.isNone:
      echoWarn mcMod.name.cyanFg, " does not have a compatible version. Skipping.."
      continue
    echoInfo "Updating ", mcMod.name.cyanFg, ".."
    manifest.updateMod(mcMod.projectId, mcModFile.get().fileId)

  echoDebug "Writing to manifest..." 
  manifest.writeToDisk()