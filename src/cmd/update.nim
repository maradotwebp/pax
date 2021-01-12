import cligen, json, options
import cmdutils
import ../lib/flow
import ../lib/io/cli, ../lib/io/files, ../lib/io/http, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/manifestutils, ../lib/obj/mods

proc cmdUpdate*(name: seq[string], strategy: InstallStrategy = InstallStrategy.recommended): void =
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

  returnIfNot promptYN("Are you sure you want to install this mod?", default=true)

  let newMcModFile = project.getModFileToInstall(mcMod, strategy)
  if newMcModFile.isNone:
    echoError "No compatible version found."
    quit(1)
  echoInfo "Updating ", mcMod.name.clrCyan, ".."
  project.updateMod(mcMod.projectId, newMcModFile.get().fileId)

  echoDebug "Writing to manifest..."
  writeFile(manifestFile, project.toJson.pretty)