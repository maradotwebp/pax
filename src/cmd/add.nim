import asyncdispatch, options, strscans
import common
import ../api/cf
import ../cli/term, ../cli/prompt
import ../util/flow
import ../modpack/files, ../modpack/install

proc addDependencies(manifest: var Manifest, file: ManifestFile,
    strategy: string): void =
  ## Recursively add dependencies of a mod
  for id in file.metadata.dependencies:
    let cfMod = waitFor(fetchMod(id))
    if manifest.isInstalled(id):
      continue
    let cfModFiles = waitFor(fetchModFiles(id))
    let selectedCfModFile = cfModFiles.selectModFile(manifest, strategy)
    if selectedCfModFile.isNone:
      echoError "Warning: unable to resolve dependencies."
    let cfModFile = selectedCfModFile.get()
    echoInfo "Installing ", cfMod.name.cyanFg, ".."
    let modToInstall = initManifestFile(
      projectId = id,
      fileId = cfModFile.fileId,
      metadata = initManifestMetadata(
        name = cfMod.name,
        explicit = false,
        installOn = "both",
        dependencies = cfModFile.dependencies
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
  var cfMod: CfMod
  var cfModFile: CfModFile

  if input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}/files/$i",
      slug, fileId):
    ## Curseforge URL with slug & fileId
    cfMod = waitFor(fetchMod(slug))
    manifest.rejectInstalledMod(cfMod.projectId)
    cfModFile = waitFor(fetchModFile(cfMod.projectId, fileId))

  elif input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}", slug):
    ## Curseforge URL with slug
    cfMod = waitFor(fetchMod(slug))
    manifest.rejectInstalledMod(cfMod.projectId)
    let cfModFiles = waitFor(fetchModFiles(cfMod.projectId))
    let selectedCfModFile = cfModFiles.selectModFile(manifest, strategy)
    if selectedCfModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    cfModFile = selectedCfModFile.get()

  elif input.scanf("$i#$i", projectId, fileId):
    ## Input in <projectid>#<fileid> format
    cfMod = waitFor(fetchMod(projectId))
    manifest.rejectInstalledMod(cfMod.projectId)
    cfModFile = waitFor(fetchModFile(projectId, fileId))

  elif input.scanf("$i", projectId):
    ## Input in <projectid> format
    cfMod = waitFor(fetchMod(projectId))
    manifest.rejectInstalledMod(cfMod.projectId)
    let cfModFiles = waitFor(fetchModFiles(cfMod.projectId))
    let selectedCfModFile = cfModFiles.selectModFile(manifest, strategy)
    if selectedCfModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    cfModFile = selectedCfModFile.get()

  else:
    ## Just search normally
    let cfMods = waitFor(fetchModsByQuery(input))
    let cfModOption = manifest.promptModChoice(cfMods, selectInstalled = false)
    if cfModOption.isNone:
      echoError "No mods found for your search."
      quit(1)
    cfMod = cfModOption.get()
    manifest.rejectInstalledMod(cfMod.projectId)
    let cfModFiles = waitFor(fetchModFiles(cfMod.projectId))
    let selectedCfModFile = cfModFiles.selectModFile(manifest, strategy)
    if selectedCfModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    cfModFile = selectedCfModFile.get()

  echo ""
  echoRoot "SELECTED MOD".dim
  echoMod(cfMod, moreInfo = true)
  echo ""

  returnIfNot promptYN("Are you sure you want to install this mod?",
      default = true)

  echoInfo "Installing ", cfMod.name.cyanFg, ".."
  let modToInstall = initManifestFile(
    projectId = cfMod.projectId,
    fileId = cfModFile.fileId,
    metadata = initManifestMetadata(
      name = cfMod.name,
      explicit = true,
      installOn = "both",
      dependencies = cfModFile.dependencies
    )
  )
  manifest.installMod(modToInstall)

  if not noDepends:
    echoDebug "Resolving Dependencies..."
    addDependencies(manifest, modToInstall, strategy)

  echoDebug "Writing to manifest.."
  manifest.writeToDisk()
