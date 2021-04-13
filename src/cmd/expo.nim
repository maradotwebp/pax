import json, streams, os, zip/zipfiles
import ../lib/io/files, ../lib/io/io, ../lib/io/term

{.passl: "-lz".}

proc cmdExport*: void =
  ## export the modpack to .zip
  requirePaxProject

  echoDebug "Extracting .zip name.."
  let manifestJson = parseJson(readFile(manifestFile))
  let name = manifestJson["name"].getStr()

  echoDebug "Exporting modpack/ folder.."
  createDirIfNotExists(outputFolder)
  var zip: ZipArchive
  let zipPath = outputZipFilePath(name)
  if not zip.open(zipPath, fmWrite):
    echoError "Creating the .zip file failed"
    return

  for path in walkDirRec(packFolder):
    let archivePath = tailDir(path)
    zip.addFile(archivePath, newFileStream(path, fmRead))

  zip.close()
  echoInfo "Pack exported to ", zipPath.clrGreen
