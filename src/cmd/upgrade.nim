import asyncdispatch, asyncfutures, sequtils, strutils, sugar, terminal, options, os
import common
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/files, ../modpack/install
import ../util/flow

proc paxUpgrade*(strategy: string): void =
  ## update all installed mods
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()
  let fileCount = manifest.files.len

  returnIfNot promptYN($fileCount & " mods will be updated to the " & $strategy & " version. Do you want to continue?", default = true)

  let cfModRequests = manifest.files.map((x) => fetchMod(x.projectId))
  let cfModFilesRequests = manifest.files.map((x) => fetchModFiles(x.projectId))
  let cfMods = all(cfModRequests)
  let cfModFiles = all(cfModFilesRequests)

  echoInfo "Loading mods.."
  waitFor(cfMods and cfModFiles)
  var modData = zip(cfMods.read(), cfModFiles.read())

  for pairs in modData:
    let (cfMod, cfModFiles) = pairs
    let cfModFile = cfModFiles.selectModFile(manifest, strategy)
    if cfModFile.isNone:
      echoWarn fgCyan, cfMod.name, resetStyle, " does not have a compatible version. Skipping.."
      continue
    echoInfo "Updating ", fgCyan, cfMod.name, resetStyle, ".."
    manifest.updateMod(cfMod.projectId, cfModFile.get().fileId)

  echoDebug "Writing to manifest..." 
  manifest.writeToDisk()