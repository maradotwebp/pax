import std/[asyncdispatch, asyncfutures, sequtils, sugar, os]
import ../api/[cfclient, cfcore]
import ../modpack/[manifest, install]
import ../term/[log, prompt]
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
    let manifestFile = manifest.getFile(mcMod.projectId)
    if manifestFile.metadata.pinned:
      echoWarn mcMod.name.fgCyan, " is pinned. Skipping.."
      continue
    let mcModFile = try:
      mcModFiles.selectAddonFile(manifest.loader, manifest.mcVersion, strategy)
    except PaxInstallError:
      echoWarn mcMod.name.fgCyan, " does not have a compatible version. Skipping.."
      continue
    echoInfo "Updating ", mcMod.name.fgCyan, ".."
    manifest.updateAddon(mcMod.projectId, mcModFile.fileId)

  echoDebug "Writing to manifest..." 
  manifest.writeToDisk()