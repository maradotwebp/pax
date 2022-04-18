import std/[asyncdispatch, os]
import common
import ../api/[cfapi, cfcore]
import ../modpack/[install, manifest]
import ../term/[log, prompt]
import ../util/flow

proc paxUpdate*(name: string, strategy: string): void =
  ## update an installed mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Loading mods.."
  let mcMods = waitFor(fetchAddonsByQuery(name))

  echoDebug "Searching for mod.."
  let mcMod = manifest.promptAddonChoice(mcMods, selectInstalled = true)

  echo ""
  echoRoot "SELECTED MOD".dim
  echoAddon(mcMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to update this mod?", default = true)

  let manifestFile = manifest.getFile(mcMod.projectId)
  if manifestFile.metadata.pinned:
    echoError "Cannot update mod - ", mcMod.name.fgCyan, " is pinned."
    return

  echoDebug "Retrieving mod versions.."
  let mcModFiles = waitFor(fetchAddonFiles(mcMod.projectId))

  let mcModFile = mcModFiles.selectAddonFile(manifest.loader, manifest.mcVersion, strategy)
  echoInfo "Updating ", mcMod.name.fgCyan, ".."
  manifest.updateAddon(mcMod.projectId, mcModFile.fileId)

  echoDebug("Writing to manifest...")
  manifest.writeToDisk()