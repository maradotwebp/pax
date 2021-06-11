import json, options
import cmdutils
import ../io/cli, ../io/files, ../io/http
import ../modpack/manifest, ../modpack/version

proc paxVersion*(version: string): void =
  ## change the minecraft version (and set the recommended forge version for it)
  requirePaxProject()

  echoDebug("Updating databases..")
  var project = projectFromJson(parseJson(readFile(manifestFile)))
  let forgeVersionJson = parseJson(fetch(forgeVersionUrl))

  let forgeVersion = forgeVersionJson.getForgeVersion(version)
  if isNone(forgeVersion):
    echoError("This is either not a minecraft version, or no forge version exists for this minecraft version.")
    quit(1)
  let manifestForgeVersion = "forge-" & ($forgeVersion.get()).split("-")[1]

  project.mcVersion = version.Version
  project.mcModloaderId = manifestForgeVersion
  writeFile(manifestFile, project.toJson.pretty)
  echoInfo("Set MC version ", fgGreen, $project.mcVersion)
  echoInfo("Set Forge version ", fgGreen, project.mcModloaderId)