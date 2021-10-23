import asyncdispatch, asyncfutures, options, os
import common
import ../api/cfcore, ../api/cfclient
import ../modpack/install, ../modpack/manifest
import ../term/log, ../term/prompt
import ../util/flow

proc paxPin*(name: string): void =
  ## pin/unpin an installed mod
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
  echoAddon(mcMod)
  echo ""

  let manifestFile = manifest.getFile(mcMod.projectId)

  if manifestFile.metadata.pinned:
    returnIfNot promptYN("Unpin this mod?", default = true)
    echoInfo "Unpinning ", mcMod.name.fgCyan, ".."
  else:
    returnIfNot promptYN("Pin this mod to the current version?", default = true)
    echoInfo "Removing ", mcMod.name.fgCyan, ".."
  
  manifestFile.metadata.pinned = not manifestFile.metadata.pinned
  updateAddon(manifest, manifestFile)

  echoDebug "Writing to manifest..."
  manifest.writeToDisk()