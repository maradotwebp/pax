import asyncdispatch, asyncfutures, options, os
import common
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/install, ../modpack/manifest
import ../util/flow

proc removeDependencies(manifest: var Manifest, file: ManifestFile): void {.used.} =
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

  returnIfNot promptYN("Are you sure you want to remove this mod?", default = true)

  var dependents = manifest.getDependents(mcMod.projectId)
  if len(dependents) > 0:
    echoRoot "Cannot remove ", mcMod.name.cyanFg, " - mod is needed by"
    for dependent in dependents:
      echoClr indentPrefix, dependent.metadata.name
  else:
    echoInfo "Removing ", mcMod.name.cyanFg, ".."
    let removedMod = manifest.removeMod(mcMod.projectId)

    removeDependencies(manifest, removedMod)

    echoDebug "Writing to manifest..."
    manifest.writeToDisk()
