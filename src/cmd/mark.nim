import asyncdispatch, asyncfutures, strutils, terminal, options, os
import common
import ../api/cf
import ../cli/term, ../cli/prompt
import ../modpack/files, ../modpack/install
import ../util/flow

proc paxMark*(name: string, mark: string): void =
  const possibleMarks = @["server","client","both","explicit","implicit"]
  if not possibleMarks.contains(mark):
    echoError "mark must be one of:"
    for possible in possibleMarks:
      echo possible
    quit(1)


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

  var createdMetadata: ManifestMetadata
  let currentFileData = manifest.getFile(cfMod.projectId)

  if @["explicit","implicit"].contains(mark):
    createdMetadata = initManifestMetadata(
      name = cfMod.name,
      explicit = (mark == "explicit"),
      installOn = currentFileData.metadata.installOn,
      dependencies = currentFileData.metadata.dependencies
    )
  else:
    createdMetadata = initManifestMetadata(
      name = cfMod.name,
      explicit = currentFileData.metadata.explicit,
      installOn = mark,
      dependencies = currentFileData.metadata.dependencies
    )

  let modToInstall = initManifestFile(
    projectId = cfMod.projectId,
    fileId = currentFileData.fileId,
    metadata = createdMetadata
  )
  discard manifest.removeMod(cfMod.projectId)
  manifest.installMod(modToInstall)

  echoInfo "Marked ", cfMod.name.cyanFg, " as ", mark
  # manifest.updateMod(cfMod.projectId, cfModFile.get().fileId)

  manifest.writeToDisk()