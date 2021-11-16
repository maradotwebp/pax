import asyncdispatch, asyncfutures, options, os
import ../api/metadata
import ../modpack/manifest, ../modpack/loader, ../modpack/version
import ../term/log

proc paxVersion*(version: string, loader: string, latest: bool): void =
  ## change the minecraft version (and set the recommended fabric/forge version for it)
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()
  let loader = if loader == "": manifest.loader else: loader

  let loaderId = waitFor(version.Version.getModloaderId(loader, latest))
  if loaderId.isNone:
    echoError "This is either not a minecraft version, or no ", $loader, " version exists for this minecraft version."
    return

  manifest.mcVersion = version.Version
  manifest.mcModloaderId = loaderId.get()

  echoDebug "Writing to manifest..."
  manifest.writeToDisk()

  echoInfo "Set MC version ", manifest.mcVersion.`$`.fgGreen
  echoDebug "Set ", $loader, " version ", manifest.mcModloaderId.fgGreen

proc paxVersion*(version: string, latest: bool): void =
  paxVersion(version, "", latest)