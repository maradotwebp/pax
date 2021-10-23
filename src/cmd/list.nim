import algorithm, asyncdispatch, asyncfutures, sequtils, strutils, options, os, sugar
import common
import ../api/cfclient, ../api/cfcore
import ../modpack/manifest, ../modpack/modinfo
import ../term/log

proc paxList*(status: bool, info: bool): void =
  ## list installed mods & their current versions
  requirePaxProject()

  echoDebug "Loading files from manifest.."
  let manifest = readManifestFromDisk()

  let fileCount = manifest.files.len
  let mcModRequests = manifest.files.map((x) => fetchAddon(x.projectId))
  let mcModFileRequests = manifest.files.map((x) => fetchAddonFile(x.projectId, x.fileId))
  let mcMods = all(mcModRequests)
  let mcModFiles = all(mcModFileRequests)

  echoInfo "Loading mods.."
  waitFor(mcMods and mcModFiles)
  let modDataOptions = zip(mcMods.read(), mcModFiles.read())
  var modData = modDataOptions.map((x) => (x[0].get(), x[1].get()))
  modData = modData.sorted((x,y) => cmp(x[0].name, y[0].name))

  echoRoot "ALL MODS ".fgMagenta, ("(" & $fileCount & ")").dim
  for index, pairs in modData:
    let (mcMod, mcModFile) = pairs
    let fileUrl = mcMod.websiteUrl & "/files/" & $mcModFile.fileId
    let compability = mcModFile.getCompability(manifest.mcVersion)
    let freshness = mcModFile.getFreshness(manifest.mcVersion, mcMod)
    let prefix = compability.getIcon() & freshness.getIcon()
    echoAddon(mcMod, prefix = prefix, url = fileUrl.dim, moreInfo = info)
    if status and info:
      echoClr "------------------------------".indent(7).dim
    if status:
      echoClr indentPrefix.indent(6), compability.getIcon(), " ", compability.getMessage()
      echoClr indentPrefix.indent(6), freshness.getIcon(), " ", freshness.getMessage()
  if fileCount == 0:
    echoClr indentPrefix, "No mods installed yet.".dim