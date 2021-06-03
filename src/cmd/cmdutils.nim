import asyncdispatch, asyncfutures, sequtils, strutils, json, options
import ../io/cli, ../io/files, ..//io/http
import ../modpack/cf, ../modpack/manifest, ../modpack/version

type
  InstallStrategy* = enum
    ## Strategy when installing/updating mods.
    ## recommended =  newest version which is compatible with the modpack version.
    ## newest = newest version which is compatible with the minor modpack version.
    recommended, newest

proc installStrategyFromString*(str: string): InstallStrategy =
  case str:
    of "recommended": return InstallStrategy.recommended
    of "newest": return InstallStrategy.newest

proc searchForMod*(project: ManifestProject, search: string, installed: bool): CfMod =
  ## let the user select a mod from a list
  ## list retrieved by searching the mod database for the search string
  var mcMods = parseJson(fetch(searchUrl(search))).modsFromJson
  if installed:
    if project.files.len == 0:
      echoError("No mods installed yet.")
      quit(1)
    mcMods = mcMods.filter(proc(m: CfMod): bool = project.isInstalled(m.projectId))
    if mcMods.len == 0:
      echoError("No mods found for your search.")
      quit(1)
    if mcMods.len == 1:
      return mcMods[0]

  echoRoot(styleDim, "RESULTS")
  for index, mcMod in mcMods:
    stdout.styledWrite(promptPrefix)
    if not installed and not project.isInstalled(mcMod.projectId):
      let count = ("[" & $(index+1) & "]").align(4)
      stdout.styledWrite(fgCyan, count, resetStyle)
    else:
      stdout.styledWrite("    ")
    stdout.styledWrite(" ", mcMod.name, " ")
    if project.isInstalled(mcMod.projectId):
      stdout.styledWrite(fgMagenta, "[installed] ", resetStyle)
    stdout.styledWriteLine(styleDim, mcMod.websiteUrl)

  var availableIndexes = toSeq(1..mcMods.len)
  if not installed:
    availableIndexes.keepItIf(not project.isInstalled(mcMods[it - 1].projectId))
  let selectedIndex = promptChoice("Select a mod", availableIndexes, "1 - " & $mcMods.len)
  let mcMod = mcMods[selectedIndex - 1]
  return mcMod


proc displayMod(project: ManifestProject, mcMod: CfMod, mcModFile: Option[CfModFile]): void =
  ## display information about the mod on the command line.
  echoRoot(styleDim, "SELECTED MOD")
  stdout.styledWrite(promptPrefix, mcMod.name)
  if mcModFile.isSome:
    stdout.styledWrite(fgMagenta, " [installed]", resetStyle)
  stdout.styledWriteLine(" ", styleDim, mcMod.websiteUrl)
  if mcModFile.isSome:
    let file = mcModFile.get()
    let fileCompabilityMessage = project.mcVersion.getFileCompability(file).getMessage()
    let fileFreshnessMessage = project.mcVersion.getFileFreshness(file, mcMod).getMessage()
    echo promptPrefix.indent(3), fileCompabilityMessage
    echo promptPrefix.indent(3), fileFreshnessMessage
    stdout.styledWriteLine(styleDim, "------------------------------".indent(4))
  stdout.styledWriteLine(promptPrefix.indent(3), fgCyan, "Description: ", resetStyle, mcMod.description)
  stdout.styledWriteLine(promptPrefix.indent(3), fgCyan, "Downloads: ", resetStyle, ($mcMod.downloads).insertSep(sep='.'))

proc displayMod*(project: ManifestProject, mcMod: CfMod, mcModFile: CfModFile): void = displayMod(project, mcMod, some(mcModFile))
proc displayMod*(project: ManifestProject, mcMod: CfMod): void = displayMod(project, mcMod, none(CfModFile))

proc getModFileToInstall*(project: ManifestProject, mcMod: CfMod, strategy: InstallStrategy): Option[CfModFile] =
  ## get the correct version of the mcMod to download based on the InstallStrategy & Loader.
  echoDebug("Retrieving mod versions..")
  let modFileContent = waitFor(asyncFetch(modFilesUrl(mcMod.projectId)))
  let allModFiles = modFileContent.parseJson.modFilesFromJson

  echoDebug("Checking ", $project.loader, " compability..")
  var latestFile = none[CfModFile]()
  for file in allModFiles:
    let onFabric = project.loader == Loader.fabric and "Fabric".Version in file.gameVersions
    let onForge = project.loader == Loader.forge and not ("Fabric".Version in file.gameVersions and not ("Forge".Version in file.gameVersions))
    let onRecommended = strategy == InstallStrategy.recommended and project.mcVersion in file.gameVersions
    let onNewest = strategy == InstallStrategy.newest and project.mcVersion.minor in file.gameVersions.map(minor)
    if latestFile.isNone or latestFile.get().fileId < file.fileId:
      if onFabric or onForge or mcMod.projectId == 361988:
        if onRecommended or onNewest:
          latestFile = some(file)
  
  return latestFile
  