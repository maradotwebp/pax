import std/[algorithm, asyncdispatch, sequtils, strutils, os, sugar]
import common
import ../api/[cfclient, cfcore]
import ../modpack/[manifest, modinfo]
import ../term/log

proc paxList*(status: bool, info: bool): void =
  ## list installed mods & their current versions
  requirePaxProject()

  echoDebug "Loading files from manifest.."
  let manifest = readManifestFromDisk()

  let fileCount = manifest.files.len
  let mcMods: Future[seq[CfAddon]] = manifest.files.map((x) => x.projectId).fetchAddons
  let mcModFiles: Future[seq[CfAddonFile]] = manifest.files.map((x) => x.fileId).fetchAddonFiles

  echoInfo "Loading mods.."
  waitFor(mcMods and mcModFiles)
  var modData = zip(mcMods.read(), mcModFiles.read())
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