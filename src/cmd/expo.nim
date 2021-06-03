import json, os, zippy/ziparchives
import ../io/cli, ../io/files

{.passl: "-lz".}

proc paxExport*: void =
  ## export the modpack to .zip
  requirePaxProject()

  echoDebug("Extracting .zip name..")
  let manifestJson = parseJson(readFile(manifestFile))
  let name = manifestJson["name"].getStr()

  echoDebug("Exporting modpack/ folder..")
  createDirIfNotExists(outputFolder)
  let zipPath = outputZipFilePath(name)
  createZipArchive(packFolder, zipPath)
  echoInfo("Pack exported to ", fgGreen, zipPath)
