import asyncdispatch, asyncfutures, strutils, terminal, options, os
import common
import ../api/cf
import ../cli/term, ../cli/prompt
import ../modpack/files, ../modpack/install
import ../util/flow

proc paxMark*(name: string, mark: string): void =
  ## mark a mod 
  requirePaxProject()

  var manifest = readManifestFromDisk()

  let cfMods = waitFor(fetchModsByQuery(name))

  echoDebug "Locating mod.."
  let cfModOption = manifest.promptModChoice(cfMods, selectInstalled = true)
  if cfModOption.isNone:
    echoError "No installed mods found for your search."
    quit(1)
  let cfMod = cfModOption.get()

  echo ""
  echoRoot "SELECTED MOD".dim
  echoMod(cfMod, moreInfo = false)
  echo ""

  returnIfNot promptYN(("Are you sure you want to mark this mod as " & mark), default = true)

  echoInfo "Marked ", cfMod.name.cyanFg, " as ", mark
  # manifest.updateMod(cfMod.projectId, cfModFile.get().fileId)

  manifest.writeToDisk()