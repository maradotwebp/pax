import asyncdispatch, asyncfutures, strutils, terminal, options, os
import common
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/files, ../modpack/install
import ../util/flow

proc paxRemove*(name: string): void =
  ## remove an installed mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Loading mods.."
  let cfMods = waitFor(fetchModsByQuery(name))

  echoDebug "Searching for mod.."
  let cfModOption = manifest.promptModChoice(cfMods, selectInstalled = true)
  if cfModOption.isNone:
    echoError "No installed mods found for your search."
    quit(1)
  let cfMod = cfModOption.get()

  echo ""
  echoRoot "SELECTED MOD".dim
  echoMod(cfMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to remove this mod?", default = true)
  
  echoInfo "Removing ", cfMod.name.cyanFg, ".."
  manifest.removeMod(cfMod.projectId)

  echoDebug "Writing to manifest..."
  manifest.writeToDisk()
