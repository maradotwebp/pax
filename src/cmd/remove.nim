import asyncdispatch, asyncfutures, options, os
import common
import ../api/cfcore, ../api/cfclient
import ../modpack/install, ../modpack/manifest
import ../term/log, ../term/prompt
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
        echoInfo "Removing ", modToRemove.metadata.name.fgCyan, ".."
        discard manifest.removeAddon(id)
        removeDependencies(manifest, modToRemove)


proc paxRemove*(name: string, strategy: string): void =
  ## remove an installed mod
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

  returnIfNot promptYN("Are you sure you want to remove this mod?", default = true)

  var dependents = manifest.getDependents(mcMod.projectId)
  if len(dependents) > 0:
    echoRoot "Cannot remove ", mcMod.name.fgCyan, " - mod is needed by"
    for dependent in dependents:
      echoClr indentPrefix, dependent.metadata.name
  else:
    echoInfo "Removing ", mcMod.name.fgCyan, ".."
    let removedMod = manifest.removeAddon(mcMod.projectId)

    removeDependencies(manifest, removedMod)

    echoDebug "Writing to manifest..."
    manifest.writeToDisk()
