import os
import term
export term

const
  projectFolder* = "./"
  packFolder* = joinPath(projectFolder, "modpack/")
  overridesFolder* = joinPath(packFolder, "overrides/")
  paxFile* = joinPath(overridesFolder, ".pax")
  manifestFile* = joinPath(packFolder, "manifest.json")
  outputFolder* = joinPath(projectFolder, ".out/")

template outputZipFilePath*(name: string): string = joinPath(outputFolder, name & ".zip")

proc createDirIfNotExists*(dir: string): void =
  ## create a dir if it doesn't exist yet
  if not existsDir(dir):
    createDir(dir)

template isPaxProject*(): bool =
  ## returns true if the current folder is a pax project folder
  existsFile(manifestFile)

template requirePaxProject*(): void =
  ## will error if the current folder isn't a pax project
  if not isPaxProject():
    echoError "The current folder isn't a pax project."
    echo promptPrefix, "To initialize a pax project, enter ", "pax init".clrRed
    return

template rejectPaxProject*(): void =
  ## will error if the current folder is a pax project
  if isPaxProject():
    echoError "The current folder is already a pax project."
    echo promptPrefix, "If you are sure you want to overwrite existing files, use the ", "--force".clrRed, " option"
    return