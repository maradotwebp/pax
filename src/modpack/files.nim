import algorithm, json, os, sequtils, sugar
import loader
import ../cli/clr, ../cli/term
import ../mc/version

export term

type
  ManifestFile* = object
    ## a file of a given project in a manifest.json.
    ## describes a specific version of a curseforge mod.
    projectId*: int
    fileId*: int
    name*: string
    explicit*: bool
    dependencies*: seq[int]

  Manifest* = object
    ## a project in a manifest.json.
    ## describes the modpack.
    name*: string
    author*: string
    version*: string
    mcVersion*: Version
    mcModloaderId*: string
    files*: seq[ManifestFile]

const
  projectFolder* = "./"
  gitIgnoreFile* = joinPath(projectFolder, ".gitignore")
  gitIgnoreContent* = staticRead("templates/.gitignore")
  githubCiFolder* = joinPath(projectFolder, ".github/workflows")
  githubCiFile* = joinPath(githubCiFolder, "main.yml")
  githubCiContent* = staticRead("templates/main.yml")
  packFolder* = joinPath(projectFolder, "modpack/")
  tempPackFolder* = joinPath(projectFolder, "temppack/")
  overridesFolder* = joinPath(packFolder, "overrides/")
  paxFile* = joinPath(overridesFolder, ".pax")
  manifestFile* = joinPath(packFolder, "manifest.json")
  outputFolder* = joinPath(projectFolder, ".out/")

proc initManifestFile*(projectId: int, fileId: int, name: string,
    explicit: bool, dependencies: seq[int]): ManifestFile =
  ## create a new manifest fmod object.
  result.projectId = projectId
  result.fileId = fileId
  result.name = name
  result.explicit = explicit
  result.dependencies = dependencies

converter toManifestFile(json: JsonNode): ManifestFile =
  ## creates a ManifestFile from manifest json
  result.projectId = json["projectID"].getInt()
  result.fileId = json["fileID"].getInt()
  result.name = json["name"].getStr()
  result.explicit = json["explicit"].getBool()
  result.dependencies = json["dependencies"].getElems().map((x) => x.getInt())

converter toJson(file: ManifestFile): JsonNode {.used.} =
  ## creates the json for a manifest file `file`
  result = %* {
    "projectID": file.projectId,
    "fileID": file.fileId,
    "required": true,
    "name": file.name,
    "explicit": file.explicit,
    "dependencies": file.dependencies
  }

converter toManifest(json: JsonNode): Manifest =
  ## creates a Manifest from manifest json
  result.name = json["name"].getStr()
  result.author = json["author"].getStr()
  result.version = json["version"].getStr()
  result.mcVersion = json["minecraft"]["version"].getStr().Version
  result.mcModloaderId = json["minecraft"]["modLoaders"][0]["id"].getStr()
  result.files = json["files"].getElems().map(toManifestFile)

converter toJson(manifest: Manifest): JsonNode =
  ## creates the json for a manifest from `manifest`
  var manifest = manifest
  manifest.files.sort((x, y) => cmp(x.projectId, y.projectId))
  result = %* {
    "minecraft": {
      "version": $manifest.mcVersion,
      "modLoaders": [{"id": manifest.mcModloaderId, "primary": true}]
    },
    "manifestType": "minecraftModpack",
    "overrides": "overrides",
    "manifestVersion": 1,
    "version": manifest.version,
    "author": manifest.author,
    "name": manifest.name,
    "files": manifest.files.map(toJson)
  }

proc loader*(manifest: Manifest): Loader =
  ## returns the loader from the manifest (either Fabric or Forge)
  return manifest.mcModloaderId.toLoader

proc isInstalled*(manifest: Manifest, projectId: int): bool =
  ## returns true if the ManifestFile with the given `projectId` is installed
  return projectId in manifest.files.map((x) => x.projectId)

proc isDepended*(manifest: Manifest, projectId: int): seq[ManifestFile] =
  ## returns true if `projectId` is found as a dependency for another mod
  return manifest.files.filter((file) => file.dependencies.any((dependency) =>
      dependency == projectId))

proc getFile*(manifest: Manifest, projectId: int): ManifestFile =
  ## returns the file with the provided `projectId`
  return manifest.files.filter((x) => x.projectId == projectId)[0]

proc installMod*(manifest: var Manifest, file: ManifestFile): void =
  ## install a mod with the given `projectId`, `fileId`, `name`, `explicitly installed`, and `dependencies`
  manifest.files = manifest.files & file

proc removeMod*(manifest: var Manifest, projectId: int): ManifestFile =
  ## remove a mod from the project with the given `projectId`, returns removed mod.
  for i, file in manifest.files:
    if file.projectId == projectId:
      manifest.files.delete(i, i)
      return file

proc updateMod*(manifest: var Manifest, projectId: int, fileId: int): void =
  ## update a mod with the given `projectId` to the given `fileId`
  var modToUpdate = removeMod(manifest, projectId)
  modToUpdate.fileId = fileId
  installMod(manifest, modToUpdate)

template isPaxProject*: bool =
  ## returns true if the current folder is a pax project folder
  fileExists(manifestFile)

template requirePaxProject*: void =
  ## will error if the current folder isn't a pax project
  if not isPaxProject():
    echoError "The current folder isn't a pax project."
    echoClr indentPrefix, "To initialize a pax project, enter ".redFg, "pax init"
    return

template rejectPaxProject*: void =
  ## will error if the current folder is a pax project
  if isPaxProject:
    echoError "The current folder is already a pax project."
    echoClr indentPrefix, "If you are sure you want to overwrite existing files, use the ",
        "--force".redFg, " option"
    return

template rejectInstalledMod*(manifest: Manifest, projectId: int): void =
  ## will error if the mod with the given projectis is already installed.
  if manifest.isInstalled(projectId):
    echoError "This mod is already installed."
    return

proc readManifestFromDisk*(path = manifestFile): Manifest =
  ## get a Manifest from disk (with `path` as the path)
  return readFile(path).parseJson.toManifest

proc writeToDisk*(manifest: Manifest, path = manifestFile): void =
  ## write `manifest` to disk (with `path` as the path)
  writeFile(path, manifest.toJson.pretty)
