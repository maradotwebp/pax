import strutils, json
import ../lib/flow
import ../lib/io/files, ../lib/io/http, ../lib/io/term
import ../lib/obj/manifest

proc cmdInit*(force = false): void =
  ## initialize a new modpack in the current directory
  if not force:
    rejectPaxProject

  returnIfNot readYesNo("Are you sure you want to create a pax project in the current folder?", default='y', prefix="")

  echoInfo "Updating databases.."
  let forgeVersionJson = parseJson(fetch(forgeVersionUrl))

  echoInfo "Creating manifest.."
  var project = ManifestProject()
  project.name = readInput("Modpack name")
  project.author = readInput("Modpack author")
  project.version = readInput("Modpack version", default="1.0.0")
  project.mcVersion = readInput("Minecraft version", default="1.16.4")
  let recommendedForgeVersion = forgeVersionJson{"by_mcversion", project.mcVersion, "recommended"}.getStr()
  let latestForgeVersion = forgeVersionJson{"by_mcversion", project.mcVersion, "latest"}.getStr()
  let forgeVersion = if recommendedForgeVersion != "": recommendedForgeVersion else: latestForgeVersion
  if forgeVersion == "":
    echoError "This is either not a minecraft version, or no forge version exists for this minecraft version."
    return
  let manifestForgeVersion = "forge-" & forgeVersion.split("-")[1]
  project.mcModloaderId = manifestForgeVersion
  echoDebug "Forge version is ", project.mcModloaderId

  echoDebug "Creating pack folder.."
  createDirIfNotExists(packFolder)
  createDirIfNotExists(overridesFolder)
  writeFile(manifestFile, project.toJson.pretty)