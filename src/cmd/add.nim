import asyncdispatch, options, strscans
import common
import ../api/cf
import ../cli/term, ../cli/prompt
import ../util/flow
import ../modpack/install, ../modpack/manifest, ../modpack/mods

proc addDependencies(manifest: var Manifest, file: ManifestFile, strategy: string): void =
  ## Recursively add dependencies of a mod
  for id in file.metadata.dependencies:
    if manifest.isInstalled(id):
      continue
    let mcMod = fetchMod(id)
    let mcModFiles = fetchModFiles(id)
    waitFor(mcMod and mcModFiles)
    let selectedMcModFile = mcModFiles.read().selectModFile(manifest, strategy)
    if selectedMcModFile.isNone:
      echoError "Warning: unable to resolve dependencies."
      quit(1)
    let mcModFile = selectedMcModFile.get()
    echoInfo "Installing ", mcMod.read().name.cyanFg, ".."
    let modToInstall = initManifestFile(
      projectId = id,
      fileId = mcModFile.fileId,
      metadata = initManifestMetadata(
        name = mcMod.read().name,
        explicit = false,
        dependencies = mcModFile.dependencies
      )
    )
    manifest.installMod(modToInstall)
    addDependencies(manifest, modToinstall, strategy)

proc strScan(input: string, strVal: var string, start: int): int =
  result = 0
  while start+result < input.len and not (input[start+result] in {'/', ' '}):
    inc result
  strVal = input.substr(start, start+result-1)

proc paxAdd*(input: string, noDepends: bool, strategy: string): void =
  ## add a new mod
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()

  echoDebug "Searching for mod.."

  var projectId: int
  var fileId: int
  var slug: string
  var mcMod: McMod
  var mcModFile: McModFile

  if input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}/files/$i", slug, fileId):
    ## Curseforge URL with slug & fileId
    mcMod = waitFor(fetchMod(slug))
    manifest.rejectInstalledMod(mcMod.projectId)
    mcModFile = waitFor(fetchModFile(mcMod.projectId, fileId))

  elif input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}", slug):
    ## Curseforge URL with slug
    mcMod = waitFor(fetchMod(slug))
    manifest.rejectInstalledMod(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.cyanFg, "."
    let mcModFiles = waitFor(fetchModFiles(mcMod.projectId))
    let selectedMcModFile = mcModFiles.selectModFile(manifest, strategy)
    if selectedMcModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    mcModFile = selectedMcModFile.get()

  elif input.scanf("$i#$i", projectId, fileId):
    ## Input in <projectid>#<fileid> format
    mcMod = waitFor(fetchMod(projectId))
    manifest.rejectInstalledMod(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.cyanFg, "."
    mcModFile = waitFor(fetchModFile(projectId, fileId))

  elif input.scanf("$i", projectId):
    ## Input in <projectid> format
    mcMod = waitFor(fetchMod(projectId))
    manifest.rejectInstalledMod(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.cyanFg, "."
    let mcModFiles = waitFor(fetchModFiles(mcMod.projectId))
    let selectedMcModFile = mcModFiles.selectModFile(manifest, strategy)
    if selectedMcModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    mcModFile = selectedMcModFile.get()

  else:
    ## Just search normally
    let mcMods = waitFor(fetchModsByQuery(input))
    let mcModOption = manifest.promptModChoice(mcMods, selectInstalled = false)
    if mcModOption.isNone:
      echoError "No mods found for your search."
      quit(1)
    mcMod = mcModOption.get()
    manifest.rejectInstalledMod(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.cyanFg, "."
    let mcModFiles = waitFor(fetchModFiles(mcMod.projectId))
    let selectedMcModFile = mcModFiles.selectModFile(manifest, strategy)
    if selectedMcModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    mcModFile = selectedMcModFile.get()

  echo ""
  echoRoot "SELECTED MOD".dim
  echoMod(mcMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to install this mod?", default = true)

  echoInfo "Installing ", mcMod.name.cyanFg, ".."
  let modToInstall = initManifestFile(
    projectId = mcMod.projectId,
    fileId = mcModFile.fileId,
    metadata = initManifestMetadata(
      name = mcMod.name,
      explicit = true,
      dependencies = mcModFile.dependencies
    )
  )
  manifest.installMod(modToInstall)

  if not noDepends:
    echoDebug "Resolving Dependencies..."
    addDependencies(manifest, modToInstall, strategy)

  echoDebug "Writing to manifest.."
  manifest.writeToDisk()
