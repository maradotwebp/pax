import std/[asyncdispatch, os]
import common
import ../api/[cfcore, cfclient]
import ../modpack/manifest
import ../term/[log, prompt]
import ../util/flow

proc paxPin*(name: string): void =
  ## pin/unpin an installed mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Loading mods.."
  let mcMods = waitFor(fetchAddonsByQuery(name))

  echoDebug "Searching for mod.."
  let mcMod = manifest.promptAddonChoice(mcMods, selectInstalled = true)

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