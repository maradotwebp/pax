import algorithm, asyncdispatch, asyncfutures, sequtils, strutils, json
import ../io/cli, ../io/files, ../io/http
import ../modpack/cf, ../modpack/manifest

proc paxList*(status: bool, info: bool): void =
  ## list installed mods & their current versions
  requirePaxProject()

  echoDebug("Loading files from manifest..")
  let manifestJson = parseJson(readFile(manifestFile))
  let project = projectFromJson(manifestJson)
  let fileCount = project.files.len
  let allModRequests = project.files.map(proc(file: ManifestFile): Future[CfMod] {.async.} =
    return (await asyncFetch(modUrl(file.projectId))).parseJson.modFromJson
  )
  let allModFileRequests = project.files.map(proc(file: ManifestFile): Future[CfModFile] {.async.} =
    return (await asyncFetch(modFileUrl(file.projectId, file.fileId))).parseJson.modFileFromJson
  )
  let mods = all(allModRequests)
  let modFiles = all(allModFileRequests)

  echoInfo("Loading mods..")
  waitFor(mods and modFiles)
  var modData = zip(mods.read(), modFiles.read())
  modData = modData.sorted(proc (x, y: (CfMod, CfModFile)): int = cmp(x[0].name, y[0].name))
  echoRoot(fgMagenta, "ALL MODS ", resetStyle, styleDim, "(", $fileCount, ")")
  for index, content in modData:
    let mcMod = content[0]
    let mcModFile = content[1]
    let fileUrl = mcMod.websiteUrl & "/files/" & $mcModFile.fileId
    let fileCompability = project.mcVersion.getFileCompability(mcModFile)
    let fileFreshness = project.mcVersion.getFileFreshness(mcModFile, mcMod)
    stdout.styledWrite(promptPrefix)
    stdout.styledWrite(fileCompability.getColor(), compabilityIcon, resetStyle)
    stdout.styledWrite(fileFreshness.getColor(), freshnessIcon, resetStyle)
    stdout.styledWriteLine(" ", mcMod.name, styleDim, " - ", fileUrl)
    if status:
      echo promptPrefix.indent(6), fileCompability.getMessage()
      echo promptPrefix.indent(6), fileFreshness.getMessage()
    if status and info:
      stdout.styledWriteLine(styleDim, "------------------------------".indent(7))
    if info:
      stdout.styledWriteLine(promptPrefix.indent(6), fgCyan, "Description: ", resetStyle, mcMod.description)
      stdout.styledWriteLine(promptPrefix.indent(6), fgCyan, "Downloads: ", resetStyle, ($mcMod.downloads).insertSep(sep='.'))
  if fileCount == 0:
    stdout.styledWriteLine(promptPrefix, styleDim, "No mods installed yet.")