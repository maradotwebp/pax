import os, zippy/ziparchives
import ../modpack/manifest
import ../term/log

proc paxExport*(path: string): void =
  ## export the modpack to .zip
  requirePaxProject()

  echoDebug "Extracting .zip.."
  let manifest = readManifestFromDisk()

  echoDebug "Exporting modpack/ folder.."
  createDir(outputFolder)
  let zipPath = if path != "":
    let (dir, _, _) = splitFile(path)
    createDir(dir)
    path
  else:
    joinPath(outputFolder, manifest.name & ".zip")
  packFolder.createZipArchive(zipPath)

  echoInfo "Pack exported to ", zipPath.fgGreen
