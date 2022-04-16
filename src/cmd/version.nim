import std/[asyncdispatch, os]
import ../api/metadata
import ../modpack/[manifest, loader, version]
import ../term/log

proc paxVersion*(version: string, loader: string, latest: bool): void =
  ## change the minecraft version (and set the recommended fabric/forge version for it)
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()
  let loader = if loader == "": manifest.loader else: loader

  let loaderId = waitFor(version.Version.getModloaderId(loader, latest))
  manifest.mcVersion = version.Version
  manifest.mcModloaderId = loaderId

  echoDebug "Writing to manifest..."
  manifest.writeToDisk()

  echoInfo "Set MC version ", manifest.mcVersion.`$`.fgGreen
  echoDebug "Set ", $loader, " version ", manifest.mcModloaderId.fgGreen

proc paxVersion*(version: string, latest: bool): void =
  paxVersion(version, "", latest)