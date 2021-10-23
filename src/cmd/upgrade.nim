import asyncdispatch, asyncfutures, sequtils, strutils, sugar, options, os
import ../api/cfclient, ../api/cfcore
import ../modpack/manifest, ../modpack/install
import ../term/log, ../term/prompt
import ../util/flow

proc paxUpgrade*(strategy: string): void =
  ## update all installed mods
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()
  let fileCount = manifest.files.len

  returnIfNot promptYN($fileCount & " mods will be updated to the " & $strategy & " version. Do you want to continue?", default = true)

  let mcModRequests = manifest.files.map((x) => fetchAddon(x.projectId))
  let mcModFilesRequests = manifest.files.map((x) => fetchAddonFiles(x.projectId))
  let mcMods = all(mcModRequests)
  let mcModFiles = all(mcModFilesRequests)

  echoInfo "Loading mods.."
  waitFor(mcMods and mcModFiles)
  var modData = zip(mcMods.read(), mcModFiles.read())

  for pairs in modData:
    let (mcMod, mcModFiles) = pairs
    let mcModFile = mcModFiles.selectAddonFile(manifest, strategy)
    let manifestFile = manifest.getFile(mcMod.get().projectId)
    if manifestFile.metadata.pinned:
      echoWarn mcMod.get().name.fgCyan, " is pinned. Skipping.."
      continue
    if mcModFile.isNone:
      echoWarn mcMod.get().name.fgCyan, " does not have a compatible version. Skipping.."
      continue
    echoInfo "Updating ", mcMod.get().name.fgCyan, ".."
    manifest.updateAddon(mcMod.get().projectId, mcModFile.get().fileId)

  echoDebug "Writing to manifest..." 
  manifest.writeToDisk()