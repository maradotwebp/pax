import asyncdispatch, asyncfutures, options, os
import common
import ../api/cfclient, ../api/cfcore
import ../modpack/install, ../modpack/manifest
import ../term/log, ../term/prompt
import ../util/flow

proc paxUpdate*(name: string, strategy: string): void =
  ## update an installed mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Loading mods.."
  let mcMods = waitFor(fetchAddonsByQuery(name))

  echoDebug "Searching for mod.."
  let mcModOption = manifest.promptAddonChoice(mcMods, selectInstalled = true)
  if mcModOption.isNone:
    echoError "No installed mods found for your search."
    quit(1)
  let mcMod = mcModOption.get()

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

  let mcModFile = mcModFiles.selectAddonFile(manifest, strategy)
  if mcModFile.isNone:
    echoError "No compatible version found."
    quit(1)
  echoInfo "Updating ", mcMod.name.fgCyan, ".."
  manifest.updateAddon(mcMod.projectId, mcModFile.get().fileId)

  echoDebug("Writing to manifest...")
  manifest.writeToDisk()