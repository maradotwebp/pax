import os, zippy/ziparchives
import ../io/cli, ../io/files

proc paxImport*(path: string, force: bool): void =
    ## import the modpack from .zip
    if force:
        removeDir(packFolder)
    else:
        rejectPaxProject()

    let (_, name, ext) = splitFile(path)
    if ext != ".zip":
        echoError("Target file is not a .zip file.")
        quit(1)
    echoDebug("Importing .zip..")

    extractAll(path, tempPackFolder)
    let nestedModpackDir = joinPath(tempPackFolder, "modpack/")
    if dirExists(nestedModpackDir):
        moveDir(nestedModpackDir, projectFolder)
    else:
        moveDir(tempPackFolder, packFolder)
    echoInfo(fgGreen, name, ext, resetStyle, " imported.")