import asyncdispatch, asyncfutures, strutils, terminal, options, os
import common
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/files, ../modpack/install
import ../util/flow

proc removeDependencies(manifest: var Manifest, file: ManifestFile): void =
  ## Recursively removes dependencies of a mod
  for id in file.metadata.dependencies:
    if not manifest.isInstalled(id):
      continue

    let modToRemove = manifest.getFile(id)

    if not modToRemove.metadata.explicit:
      let dependents = manifest.getDependents(id)
      if len(dependents) == 0:
        echoInfo "Removing ", modToRemove.metadata.name.cyanFg, ".."
        discard manifest.removeMod(id)
        removeDependencies(manifest, modToRemove)


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

  returnIfNot promptYN("Are you sure you want to remove this mod?", default = true)

  var dependents = manifest.getDependents(cfMod.projectId)
  if len(dependents) > 0:
    echoRoot "Cannot remove ", cfMod.name.cyanFg, " - mod is needed by"
    for dependent in dependents:
      echoClr indentPrefix, dependent.metadata.name
  else:
    echoInfo "Removing ", cfMod.name.cyanFg, ".."
    let removedMod = manifest.removeMod(cfMod.projectId)

    removeDependencies(manifest, removedMod)

    echoDebug "Writing to manifest..."
    manifest.writeToDisk()
