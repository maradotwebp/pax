import cligen, json
import cmdutils
import ../lib/flow
import ../lib/io/cli, ../lib/io/files, ../lib/io/http, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/manifestutils, ../lib/obj/mods

proc cmdRemove*(name: seq[string]): void =
  ## remove an installed mod
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

  returnIfNot promptYN("Are you sure you want to remove this mod?", default=true)
  
  echoInfo "Removing ", mcMod.name.clrCyan, ".."
  project.removeMod(mcMod.projectId)

  echoDebug "Writing to manifest..."
  writeFile(manifestFile, project.toJson.pretty)
