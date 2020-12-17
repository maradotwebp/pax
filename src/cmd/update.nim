import cligen, json, sequtils, tables, options
import cmdutils
import ../lib/genutils
import ../lib/io/cli, ../lib/io/files, ../lib/io/http, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/manifestutils, ../lib/obj/mods, ../lib/obj/verutils

proc cmdUpdate*(name: seq[string]): void =
  ## update an installed mod
  requirePaxProject
  if name.len == 0:
    stderr.write "Missing these required parameters:\n"
    stderr.write "  name\n"
    raise newException(ParseError, "")

  echoDebug "Loading data from manifest.."
  var project = parseJson(readFile(manifestFile)).projectFromJson
  let search = name.join(" ")

  echoDebug "Searching for mod.."
  let mcMod = project.searchForMod(search, installed=true)

  echo ""
  let file = project.getFile(mcMod.projectId)
  let mcModFile = parseJson(fetch(modFileUrl(file.projectId, file.fileId))).modFileFromJson
  project.displayMod(mcMod, mcModFile)
  echo ""

  let installMethod = promptChoice("Update to recommended or newest compatible version?", @['r', 'n'], format="[r]ecommended, [n]ewest", default='r')
  
  echoInfo "Updating ", mcMod.name.clrCyan, ".."
  let latestFiles = mcMod.gameVersionLatestFiles
  let recommendedVersion = project.mcVersion
  let newestVersion = toSeq(latestFiles.keys).newest(project.mcVersion)
  let installVersion = case installMethod
    of 'r': latestFiles.hasKey(recommendedVersion) ? (some(recommendedVersion), newestVersion)
    else: newestVersion
  if installVersion.isNone:
    echoError "No compatible version found."
    return
  project.updateMod(mcMod.projectId, latestFiles[installVersion.get()])

  echoDebug "Writing to manifest..."
  writeFile(manifestFile, project.toJson.pretty)