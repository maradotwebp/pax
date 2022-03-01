import asyncdispatch, options, strscans
import common
import ../api/cfclient, ../api/cfcore
import ../modpack/install, ../modpack/manifest
import ../term/log, ../term/prompt
import ../util/flow

proc addDependencies(manifest: var Manifest, file: ManifestFile, strategy: string): void =
  ## Recursively add dependencies of a mod
  for id in file.metadata.dependencies:
    if manifest.isInstalled(id):
      continue
    let mcMod = fetchAddon(id)
    let mcModFiles = fetchAddonFiles(id)
    waitFor(mcMod and mcModFiles)
    let selectedMcModFile = mcModFiles.read().selectAddonFile(manifest, strategy)
    if mcMod.read().isNone or selectedMcModFile.isNone:
      echoError "Warning: unable to resolve dependencies."
      quit(1)
    let mcModFile = selectedMcModFile.get()
    echoInfo "Installing ", mcMod.read().get().name.fgCyan, ".."
    let modToInstall = initManifestFile(
      projectId = id,
      fileId = mcModFile.fileId,
      metadata = initManifestMetadata(
        name = mcMod.read().get().name,
        explicit = false,
        pinned = false,
        dependencies = mcModFile.dependencies
      )
    )
    manifest.installAddon(modToInstall)
    addDependencies(manifest, modToinstall, strategy)

proc strScan(input: string, strVal: var string, start: int): int =
  result = 0
  while start+result < input.len and not (input[start+result] in {'/', ' '}):
    inc result
  strVal = input.substr(start, start+result-1)

proc paxAdd*(input: string, noDepends: bool, strategy: string, addonType: string): void =
  ## add a new mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Searching for mod.."

  var projectId: int
  var fileId: int
  var slug: string
  var mcMod: CfAddon
  var mcModFile: CfAddonFile

  if input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}/files/$i", slug, fileId):
    ## Curseforge URL with slug & fileId
    let mcModOption = waitFor(fetchAddon(slug))
    if mcModOption.isNone:
      echoError "This url is not correct."
      quit(1)
    mcMod = mcModOption.get()
    manifest.rejectInstalledAddon(mcMod.projectId)
    let mcModFileOption = waitFor(fetchAddonFile(mcMod.projectId, fileId))
    if mcModOption.isNone:
      echoError "This url is not correct."
      quit(1)
    mcModFile = mcModFileOption.get()

  elif input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}", slug):
    ## Curseforge URL with slug
    let mcModOption = waitFor(fetchAddon(slug))
    if mcModOption.isNone:
      echoError "This url is not correct."
      quit(1)
    mcMod = mcModOption.get()
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    let mcModFiles = waitFor(fetchAddonFiles(mcMod.projectId))
    let selectedMcModFile = mcModFiles.selectAddonFile(manifest, strategy)
    if selectedMcModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    mcModFile = selectedMcModFile.get()

  elif input.scanf("$i#$i", projectId, fileId):
    ## Input in <projectid>#<fileid> format
    let mcModOption = waitFor(fetchAddon(projectId))
    if mcModOption.isNone:
      echoError "There exists no addon with the given projectId."
      quit(1)
    mcMod = mcModOption.get()
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    let mcModFileOption = waitFor(fetchAddonFile(mcMod.projectId, fileId))
    if mcModOption.isNone:
      echoError "There exists no addon with the given fileId."
      quit(1)
    mcModFile = mcModFileOption.get()

  elif input.scanf("$i", projectId):
    ## Input in <projectid> format
    let mcModOption = waitFor(fetchAddon(projectId))
    if mcModOption.isNone:
      echoError "There exists no addon with the given projectId."
      quit(1)
    mcMod = mcModOption.get()
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    let mcModFiles = waitFor(fetchAddonFiles(mcMod.projectId))
    let selectedMcModFile = mcModFiles.selectAddonFile(manifest, strategy)
    if selectedMcModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    mcModFile = selectedMcModFile.get()

  else:
    ## Just search normally
    let addonType: Option[CfAddonGameCategory] = case addonType:
      of "mod":
        some(CfAddonGameCategory.Mod)
      of "resourcepack":
        some(CfAddonGameCategory.Resourcepack)
      else:
        none[CfAddonGameCategory]()
    let mcMods = waitFor(fetchAddonsByQuery(input, addonType))
    let mcModOption = manifest.promptAddonChoice(mcMods, selectInstalled = false)
    if mcModOption.isNone:
      echoError "No mods found for your search."
      quit(1)
    mcMod = mcModOption.get()
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    let mcModFiles = waitFor(fetchAddonFiles(mcMod.projectId))
    let selectedMcModFile = mcModFiles.selectAddonFile(manifest, strategy)
    if selectedMcModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    mcModFile = selectedMcModFile.get()

  echo ""
  echoRoot "SELECTED MOD".dim
  echoAddon(mcMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to install this mod?", default = true)

  echoInfo "Installing ", mcMod.name.fgCyan, ".."
  let modToInstall = initManifestFile(
    projectId = mcMod.projectId,
    fileId = mcModFile.fileId,
    metadata = initManifestMetadata(
      name = mcMod.name,
      explicit = true,
      pinned = false,
      dependencies = mcModFile.dependencies
    )
  )
  manifest.installAddon(modToInstall)

  if not noDepends:
    echoDebug "Resolving Dependencies..."
    addDependencies(manifest, modToInstall, strategy)

  echoDebug "Writing to manifest.."
  manifest.writeToDisk()
