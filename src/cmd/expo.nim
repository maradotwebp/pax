import os, zippy/ziparchives
import ../cli/term
import ../modpack/manifest

proc paxExport*: void =
  ## export the modpack to .zip
  requirePaxProject()

  echoDebug "Extracting .zip.."
  let manifest = readManifestFromDisk()

  echoDebug "Exporting modpack/ folder.."
  createDir(outputFolder)
  let zipPath = joinPath(outputFolder, manifest.name & ".zip")
  packFolder.createZipArchive(zipPath)

  echoInfo "Pack exported to ", zipPath.greenFg
