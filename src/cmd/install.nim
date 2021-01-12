import cligen, json
import cmdutils
import ../lib/flow
import ../lib/io/cli, ../lib/io/files, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/manifestutils, ../lib/obj/mods

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

  let mcModFile = project.getModFileToInstall(mcMod, strategy)
  echoInfo "Installing ", mcMod.name.clrCyan, ".."
  project.installMod(mcMod.projectId, mcModFile.fileId)

  echoDebug "Writing to manifest..."
  writeFile(manifestFile, project.toJson.pretty)
