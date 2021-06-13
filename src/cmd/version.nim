import asyncdispatch, asyncfutures, strutils, terminal, options, os
import common
import ../api/metadata
import ../cli/term
import ../mc/version
import ../modpack/files, ../modpack/install, ../modpack/loader

proc paxVersion*(version: string, loader: string): void =
  ## change the minecraft version (and set the recommended forge version for it)
  requirePaxProject()

  echoDebug "Loading data from manifest.."
  var manifest = readManifestFromDisk()
  let loader = manifest.loader

  let loaderId = waitFor(manifest.mcVersion.getMcModloaderId(loader))
  if loaderId.isNone:
    echoError "This is either not a minecraft version, or no ", loader, " version exists for this minecraft version."
    quit(1)

  manifest.mcVersion = version.Version
  manifest.mcModloaderId = loaderId.get()

  echoDebug "Writing to manifest..."
  manifest.writeToDisk()

  echoInfo "Set MC version ", fgGreen, $manifest.mcVersion
  echoDebug "Set ", $loader, " version ", fgGreen, manifest.mcModloaderId

proc paxVersion*(version: string): void =
  paxVersion(version, "")