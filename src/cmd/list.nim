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

  echoRoot fgMagenta, "ALL MODS ", resetStyle, styleDim, "(", $fileCount, ")"
  for index, pairs in modData:
    let (cfMod, cfModFile) = pairs
    let fileUrl = cfMod.websiteUrl & "/files/" & $cfModFile.fileId
    let compability = cfModFile.getCompability(manifest.mcVersion)
    let freshness = cfModFile.getFreshness(manifest.mcVersion, cfMod)
    stdout.styledWrite(indentPrefix)
    stdout.styledWrite(compability.getColor(), compabilityIcon, resetStyle)
    stdout.styledWrite(freshness.getColor(), freshnessIcon, resetStyle)
    stdout.styledWriteLine(" ", cfMod.name, styleDim, " - ", fileUrl)
    if status:
      echo indentPrefix.indent(6), compability.getMessage()
      echo indentPrefix.indent(6), freshness.getMessage()
    if status and info:
      stdout.styledWriteLine(styleDim, "------------------------------".indent(7))
    if info:
      stdout.styledWriteLine(indentPrefix.indent(6), fgCyan, "Description: ", resetStyle, cfMod.description)
      stdout.styledWriteLine(indentPrefix.indent(6), fgCyan, "Downloads: ", resetStyle, cfMod.downloads.`$`.insertSep(sep='.'))
  if fileCount == 0:
    stdout.styledWriteLine(indentPrefix, styleDim, "No mods installed yet.")