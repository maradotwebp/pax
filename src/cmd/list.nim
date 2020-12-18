import algorithm, asyncdispatch, asyncfutures, sequtils, strutils, json
import ../lib/io/files, ../lib/io/http, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/mods, ../lib/obj/modutils

proc cmdList*(status: bool = false, info: bool = false): void =
  ## list installed mods & their current versions
  requirePaxProject

  echoDebug "Loading files from manifest.."
  let manifestJson = parseJson(readFile(manifestFile))
  let project = projectFromJson(manifestJson)
  let fileCount = project.files.len
  let allModRequests = project.files.map(proc(file: ManifestFile): Future[McMod] {.async.} =
    return (await asyncFetch(modUrl(file.projectId))).parseJson.modFromJson
  )
  let allModFileRequests = project.files.map(proc(file: ManifestFile): Future[McModFile] {.async.} =
    return (await asyncFetch(modFileUrl(file.projectId, file.fileId))).parseJson.modFileFromJson
  )
  let mods = all(allModRequests)
  let modFiles = all(allModFileRequests)

  echoInfo "Loading mods.."
  waitFor(mods and modFiles)
  var modData = zip(mods.read(), modFiles.read())
  modData = modData.sorted(proc (x, y: (McMod, McModFile)): int = cmp(x[0].name, y[0].name))
  echoRoot "ALL MODS ".clrMagenta, ("(" & $fileCount & ")").clrGray
  for index, content in modData:
    let mcMod = content[0]
    let mcModFile = content[1]
    let fileUrl = mcMod.websiteUrl & "/files/" & $mcModFile.fileId
    let fileCompability = mcModFile.getFileCompability(project.mcVersion)
    let fileFreshness = mcModFile.getFileFreshness(project.mcVersion, mcMod)
    echo promptPrefix, fileCompability.getIcon(), fileFreshness.getIcon(), " ", mcMod.name, " ", fileUrl.clrGray
    if status:
      echo promptPrefix.indent(6), fileCompability.getMessage()
      echo promptPrefix.indent(6), fileFreshness.getMessage()
    if status and info:
      echo "------------------------------".indent(7).clrGray
    if info:
      echo promptPrefix.indent(6), "Description: ".clrCyan, mcMod.description
      echo promptPrefix.indent(6), "Downloads: ".clrCyan, ($mcMod.downloads).insertSep(sep='.')
  if fileCount == 0:
    echo promptPrefix, "No mods installed yet.".clrGray