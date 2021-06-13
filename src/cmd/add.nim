import asyncdispatch, options
import common
import ../api/cf
import ../cli/term, ../cli/prompt
import ../util/flow
import ../modpack/files, ../modpack/install

proc paxAdd*(name: string, strategy: string): void =
  ## add a new mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Loading mods.."
  let cfMods = waitFor(fetchModsByQuery(name))

  echoDebug "Searching for mod.."
  let cfModOption = manifest.promptModChoice(cfMods, selectInstalled = false)
  if cfModOption.isNone:
    echoError "No mods found for your search."
    quit(1)
  let cfMod = cfModOption.get()

  echo ""
  echoRoot styleDim, "SELECTED MOD"
  echoMod(cfMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to install this mod?", default = true)

  echoDebug "Retrieving mod versions.."
  let cfModFiles = waitFor(fetchModFiles(cfMod.projectId))

  let cfModFile = cfModFiles.selectModFile(manifest, strategy)
  if cfModFile.isNone:
    echoError "No compatible version found."
    quit(1)
  echoInfo "Installing ", fgCyan, cfMod.name, resetStyle, ".."
  manifest.installMod(cfMod.projectId, cfModFile.get().fileId)

  echoDebug "Writing to manifest.."
  manifest.writeToDisk()

