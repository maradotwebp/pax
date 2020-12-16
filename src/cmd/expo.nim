import json, os, nim_miniz
import ../lib/io/files, ../lib/io/io, ../lib/io/term

proc cmdExport*: void =
  ## export the modpack to .zip
  requirePaxProject

  echoDebug "Extracting .zip name.."
  let manifestJson = parseJson(readFile(manifestFile))
  let name = manifestJson["name"].getStr()

  echoDebug "Exporting modpack/ folder.."
  createDirIfNotExists(outputFolder)
  var zip: Zip
  let zipPath = outputZipFilePath(name)
  if not zip.open(zipPath, fmWrite):
    echoError "Creating the .zip file failed"
    return

  for path in walkDirRec(packFolder):
    let zipPath = tailDir(path)
    zip.add_file(path, archivePath=zipPath)

  zip.close()
  echoInfo "Pack exported to ", zipPath.clrGreen
    