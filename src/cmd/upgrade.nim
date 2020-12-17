import asyncdispatch, asyncfutures, json, sequtils, tables, options
import cmdutils
import ../lib/flow
import ../lib/io/cli, ../lib/io/files, ../lib/io/http, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/manifestutils, ../lib/obj/mods, ../lib/obj/verutils

proc cmdUpgrade*(strategy: InstallStrategy = InstallStrategy.recommended): void =
  ## update all installed mods
  requirePaxProject

  echoDebug "Loading data from manifest.."
  var project = parseJson(readFile(manifestFile)).projectFromJson
  let fileCount = project.files.len
  let allModRequests = project.files.map(proc(file: ManifestFile): Future[McMod] {.async.} =
    return (await asyncFetch(modUrl(file.projectId))).parseJson.modFromJson
  )

  echoInfo "Loading mods.."
  let mods = waitFor(all(allModRequests))

  returnIfNot promptYN(($fileCount).clrMagenta & " mods will be updated to the " & $strategy & " version. Do you want to continue?", default=true)

  for mcMod in mods:
    let latestFiles = mcMod.gameVersionLatestFiles
    let installVersion = project.getVersionToInstall(mcMod, strategy)
    if installVersion.isNone:
      echoWarn mcMod.name.clrCyan, " does not have a compatible version. Skipping.."
      continue
    echoInfo "Updating ", mcMod.name.clrCyan, " for version ", ($installVersion.get()).clrCyan, ".."
    project.updateMod(mcMod.projectId, latestFiles[installVersion.get()])

  echoDebug "Writing to manifest..."
  writeFile(manifestFile, project.toJson.pretty)