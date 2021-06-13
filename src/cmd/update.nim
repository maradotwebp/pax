import asyncdispatch, asyncfutures, strutils, terminal, options, os
import common
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/files, ../modpack/install
import ../util/flow

proc paxUpdate*(name: string, strategy: string): void =
  ## update an installed mod
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
  echoRoot styleDim, "SELECTED MOD"
  echoMod(cfMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to update this mod?", default = true)

  echoDebug "Retrieving mod versions.."
  let cfModFiles = waitFor(fetchModFiles(cfMod.projectId))

  let cfModFile = cfModFiles.selectModFile(manifest, strategy)
  if cfModFile.isNone:
    echoError "No compatible version found."
    quit(1)
  echoInfo "Updating ", fgCyan, cfMod.name, resetStyle, ".."
  manifest.updateMod(cfMod.projectId, cfModFile.get().fileId)

  echoDebug("Writing to manifest...")
  manifest.writeToDisk()