import cligen, json, sequtils, tables, options
import cmdutils
import ../lib/flow, ../lib/genutils
import ../lib/io/cli, ../lib/io/files, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/manifestutils, ../lib/obj/mods, ../lib/obj/verutils

proc cmdInstall*(name: seq[string], strategy: InstallStrategy = InstallStrategy.recommended): void =
  ## install a new mod
  requirePaxProject
  if name.len == 0:
    stderr.write "Missing these required parameters:\n"
    stderr.write "  name\n"
    raise newException(ParseError, "")

  echoDebug "Loading data from manifest.."
  var project = parseJson(readFile(manifestFile)).projectFromJson
  let search = name.join(" ")

  echoDebug "Searching for mod.."
  let mcMod = project.searchForMod(search, installed=false)

  echo ""
  project.displayMod(mcMod)
  echo ""

  returnIfNot promptYN("Are you sure you want to install this mod?", default=true)
  
  let latestFiles = mcMod.gameVersionLatestFiles
  let recommendedVersion = project.mcVersion
  let newestVersion = toSeq(latestFiles.keys).newest(project.mcVersion)
  let installVersion = case strategy
    of recommended: latestFiles.hasKey(recommendedVersion) ? (some(recommendedVersion), newestVersion)
    else: newestVersion
  if installVersion.isNone:
    echoError "No compatible version found."
    return
  echoInfo "Installing ", mcMod.name.clrCyan, " for version ", ($installVersion.get()).clrCyan, ".."
  project.installMod(mcMod.projectId, latestFiles[installVersion.get()])

  echoDebug "Writing to manifest..."
  writeFile(manifestFile, project.toJson.pretty)
