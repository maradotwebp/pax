import algorithm, asyncdispatch, asyncfutures, sequtils, strutils, terminal, os, sugar
import common
import ../api/cf
import ../cli/term
import ../modpack/files, ../modpack/install, ../modpack/modinfo

proc paxList*(status: bool, info: bool): void =
  ## list installed mods & their current versions
  requirePaxProject()

  echoDebug "Loading files from manifest.."
  let manifest = readManifestFromDisk()

  let fileCount = manifest.files.len
  let cfModRequests = manifest.files.map((x) => fetchMod(x.projectId))
  let cfModFileRequests = manifest.files.map((x) => fetchModFile(x.projectId, x.fileId))
  let cfMods = all(cfModRequests)
  let cfModFiles = all(cfModFileRequests)

  echoInfo "Loading mods.."
  waitFor(cfMods and cfModFiles)
  var modData = zip(cfMods.read(), cfModFiles.read())
  modData = modData.sorted((x,y) => cmp(x[0].name, y[0].name))

  echoRoot "ALL MODS ".magentaFg, ("(" & $fileCount & ")").dim
  for index, pairs in modData:
    let (cfMod, cfModFile) = pairs
    let fileUrl = cfMod.websiteUrl & "/files/" & $cfModFile.fileId
    let compability = cfModFile.getCompability(manifest.mcVersion)
    let freshness = cfModFile.getFreshness(manifest.mcVersion, cfMod)
    echoClr indentPrefix, compability.getIcon(), freshness.getIcon(), " ", cfMod.name, (" - " & fileUrl).dim
    if status:
      echo indentPrefix.indent(6), compability.getMessage()
      echo indentPrefix.indent(6), freshness.getMessage()
    if status and info:
      echoClr "------------------------------".indent(7).dim
    if info:
      echoClr indentPrefix.indent(6), "Description: ".cyanFg, cfMod.description
      echoClr indentPrefix.indent(6), "Downloads: ".cyanFg, cfMod.downloads.`$`.insertSep(sep='.')
  if fileCount == 0:
    echoClr indentPrefix, "No mods installed yet.".dim