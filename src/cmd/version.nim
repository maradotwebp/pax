import json, options
import cmdutils
import ../io/cli, ../io/files, ../io/http
import ../modpack/manifest, ../modpack/version

proc paxVersion*(version: string): void =
  ## change the minecraft version (and set the recommended forge version for it)
  requirePaxProject()

  var project = projectFromJson(parseJson(readFile(manifestFile)))
  let loader = project.loader
  var loaderVersion: Option[Version]
  if loader == Loader.forge:
    let forgeVersionJson = parseJson(fetch(forgeVersionUrl))
    loaderVersion = forgeVersionJson.getForgeVersion($version)
  else:
    let fabricVersionJson = parseJson(fetch(fabricVersionUrl($version)))
    loaderVersion = fabricVersionJson.getFabricVersion()
  if isNone(loaderVersion):
    echoError("This is either not a minecraft version, or no ", $loader, " version exists for this minecraft version.")
    quit(1)
  var manifestLoaderVersion: string
  if loader == Loader.forge:
    manifestLoaderVersion = "forge-" & ($loaderVersion.get()).split("-")[1]
  else:
    manifestLoaderVersion = "fabric-" & ($loaderVersion.get())

  project.mcVersion = version.Version
  project.mcModloaderId = manifestLoaderVersion
  writeFile(manifestFile, project.toJson.pretty)
  echoInfo("Set MC version ", fgGreen, $project.mcVersion)
  echoDebug("Set ", $loader, " version ", fgGreen, project.mcModloaderId)