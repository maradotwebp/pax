import os
import term
export term

const
  projectFolder* = "./"
  cacheFolder* = joinPath(projectFolder, ".pax/")
  projectFile* = joinPath(cacheFolder, ".pax")
  forgeVersionFile* = joinPath(cacheFolder, "forge-ver.json")
  packFolder* = joinPath(projectFolder, "modpack/")
  overridesFolder* = joinPath(packFolder, "overrides/")
  manifestFile* = joinPath(packFolder, "manifest.json")

proc createDirIfNotExists*(dir: string): void =
  ## create a dir if it doesn't exist yet
  if not existsDir(dir):
    createDir(dir)

template isPaxProject*(): bool =
  ## returns true if the current folder is a pax project folder
  existsFile(projectFile)

template requirePaxProject*(): void =
  ## will error if the current folder isn't a pax project
  if not isPaxProject():
    echoError "The current folder isn't a pax project."
    return

template rejectPaxProject*(): void =
  ## will error if the current folder is a pax project
  if isPaxProject():
    echoError "The current folder is already a pax project."
    return