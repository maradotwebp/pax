import asyncdispatch, asyncfutures, options, os
import common
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/install, ../modpack/manifest
import ../util/flow

proc paxUpdate*(name: string, strategy: string): void =
  ## update an installed mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Loading mods.."
  let mcMods = waitFor(fetchModsByQuery(name))

  echoDebug "Searching for mod.."
  let mcModOption = manifest.promptModChoice(mcMods, selectInstalled = true)
  if mcModOption.isNone:
    echoError "No installed mods found for your search."
    quit(1)
  let mcMod = mcModOption.get()

  echo ""
  echoRoot "SELECTED MOD".dim
  echoMod(mcMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to update this mod?", default = true)

  echoDebug "Retrieving mod versions.."
  let mcModFiles = waitFor(fetchModFiles(mcMod.projectId))

  let mcModFile = mcModFiles.selectModFile(manifest, strategy)
  if mcModFile.isNone:
    echoError "No compatible version found."
    quit(1)
  echoInfo "Updating ", mcMod.name.cyanFg, ".."
  manifest.updateMod(mcMod.projectId, mcModFile.get().fileId)

  echoDebug("Writing to manifest...")
  manifest.writeToDisk()