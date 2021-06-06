import cli, terminal, os
export cli, terminal

const
  projectFolder* = "./"
  packFolder* = joinPath(projectFolder, "modpack/")
  tempPackFolder* = joinPath(projectFolder, "temppack/")
  overridesFolder* = joinPath(packFolder, "overrides/")
  paxFile* = joinPath(overridesFolder, ".pax")
  manifestFile* = joinPath(packFolder, "manifest.json")
  outputFolder* = joinPath(projectFolder, ".out/")

template outputZipFilePath*(name: string): string =
  ## retrieve the path to the the output zip file.
  joinPath(outputFolder, name & ".zip")

proc createDirIfNotExists*(dir: string): void =
  ## create a dir if it doesn't exist yet
  if not dirExists(dir):
    createDir(dir)

template isPaxProject*(): bool =
  ## returns true if the current folder is a pax project folder
  fileExists(manifestFile)

template requirePaxProject*(): void =
  ## will error if the current folder isn't a pax project
  if not isPaxProject():
    echoError "The current folder isn't a pax project."
    echoIndent "To initialize a pax project, enter ", fgRed, "pax init"
    return

template rejectPaxProject*(): void =
  ## will error if the current folder is a pax project
  if isPaxProject():
    echoError "The current folder is already a pax project."
    echoIndent "If you are sure you want to overwrite existing files, use the ", fgRed, "--force", resetStyle, " option"
    return