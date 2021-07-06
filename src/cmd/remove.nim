import asyncdispatch, asyncfutures, strutils, terminal, options, os
import common
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/files, ../modpack/install
import ../util/flow

proc paxRemove*(name: string, strategy: string): void =
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

  returnIfNot promptYN("Are you sure you want to remove this mod?",
      default = true)

  echoInfo "Removing ", cfMod.name.cyanFg, ".."
  manifest.removeMod(cfMod.projectId)

  let cfModFiles = waitFor(fetchModFiles(cfMod.projectId))
  let selectedCfModFile = cfModFiles.selectModFile(manifest, strategy)
  if not selectedCfModFile.isNone:
    let cfModFile = selectedCfModFile.get()

    if len(cfModFile.dependencies) > 0:
      if promptYN("Do you want to remove dependencies?", default = true):
        for id in cfModFile.dependencies:
          let cfMod = waitFor(fetchMod(id))
          if not manifest.isInstalled(id):
            continue

          let cfModFiles = waitFor(fetchModFiles(id))
          let selectedCfModFile = cfModFiles.selectModFile(manifest, strategy)
          if selectedCfModFile.isNone:
            echoError "Warning: unable to resolve dependencies."
          let cfModFile = selectedCfModFile.get()
          echoInfo "Removing ", cfMod.name.cyanFg, ".."
          manifest.removeMod(id)

  echoDebug "Writing to manifest..."
  manifest.writeToDisk()
