import asyncdispatch, options, strscans
import common
import ../api/cf
import ../cli/term, ../cli/prompt
import ../util/flow
import ../modpack/files, ../modpack/install

proc strScan(input: string, strVal: var string, start: int): int =
  result = 0
  while start+result < input.len and not (input[start+result] in {'/', ' '}):
    inc result
  strVal = input.substr(start, start+result-1)

proc paxAdd*(input: string, strategy: string): void =
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

  if input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}/files/$i", slug, fileId):
    ## Curseforge URL with slug & fileId
    cfMod = waitFor(fetchMod(slug))
    cfModFile = waitFor(fetchModFile(cfMod.projectId, fileId))

  elif input.scanf("https://www.curseforge.com/minecraft/mc-mods/${strScan}", slug):
    ## Curseforge URL with slug
    cfMod = waitFor(fetchMod(slug))
    let cfModFiles = waitFor(fetchModFiles(cfMod.projectId))
    let selectedCfModFile = cfModFiles.selectModFile(manifest, strategy)
    if selectedCfModFile.isNone:
      echoError "No compatible version found."
      quit(1)
    cfModFile = selectedCfModFile.get()

  elif input.scanf("$i#$i", projectId, fileId):
    ## Input in <projectid>#<fileid> format
    cfMod = waitFor(fetchMod(projectId))
    cfModFile = waitFor(fetchModFile(projectId, fileId))

  elif input.scanf("$i", projectId):
    ## Input in <projectid> format
    cfMod = waitFor(fetchMod(projectId))
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

  returnIfNot promptYN("Are you sure you want to install this mod?", default = true)

  echoInfo "Installing ", cfMod.name.cyanFg, ".."
  manifest.installMod(cfMod.projectId, cfModFile.fileId)

  echoDebug "Writing to manifest.."
  manifest.writeToDisk()

