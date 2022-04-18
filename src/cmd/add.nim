import std/[asyncdispatch, options, strscans]
import common
import ../api/[cfapi, cfcore]
import ../modpack/[install, manifest]
import ../term/[log, prompt]
import ../util/flow

proc addDependencies(manifest: var Manifest, file: ManifestFile, strategy: string): void =
  ## Recursively add dependencies of a mod
  for id in file.metadata.dependencies:
    if manifest.isInstalled(id):
      continue
    let mcMod = fetchAddon(id)
    let mcModFiles = fetchAddonFiles(id)
    waitFor(mcMod and mcModFiles)
    let mcModFile = mcModFiles.read().selectAddonFile(manifest.loader, manifest.mcVersion, strategy)
    echoInfo "Installing ", mcMod.read().name.fgCyan, ".."
    let modToInstall = initManifestFile(
      projectId = id,
      fileId = mcModFile.fileId,
      metadata = initManifestMetadata(
        name = mcMod.read().name,
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
    mcMod = waitFor(fetchAddon(slug))
    manifest.rejectInstalledAddon(mcMod.projectId)
    mcModFile = waitFor(fetchAddonFile(mcMod.projectId, fileId))

  elif input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}", slug):
    ## Curseforge URL with slug
    mcMod = waitFor(fetchAddon(slug))
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    let mcModFiles = waitFor(fetchAddonFiles(mcMod.projectId))
    mcModFile = mcModFiles.selectAddonFile(manifest.loader, manifest.mcVersion, strategy)

  elif input.scanf("$i#$i", projectId, fileId):
    ## Input in <projectid>#<fileid> format
    mcMod = waitFor(fetchAddon(projectId))
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    mcModFile = waitFor(fetchAddonFile(mcMod.projectId, fileId))

  elif input.scanf("$i", projectId):
    ## Input in <projectid> format
    mcMod = waitFor(fetchAddon(projectId))
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    let mcModFiles = waitFor(fetchAddonFiles(mcMod.projectId))
    mcModFile = mcModFiles.selectAddonFile(manifest.loader, manifest.mcVersion, strategy)

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
    mcMod = manifest.promptAddonChoice(mcMods, selectInstalled = false)
    manifest.rejectInstalledAddon(mcMod.projectId)
    echoDebug "Found mod ", mcMod.name.fgCyan, "."
    let mcModFiles = waitFor(fetchAddonFiles(mcMod.projectId))
    mcModFile = mcModFiles.selectAddonFile(manifest.loader, manifest.mcVersion, strategy)

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
