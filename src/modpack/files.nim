import algorithm, json, os, sequtils, sugar
import loader
import ../cli/term
import ../mc/version

export term

type
  ManifestFile* = object
    ## a file of a given project in a manifest.json.
    ## describes a specific version of a curseforge mod.
    projectId*: int
    fileId*: int

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
  packFolder* = joinPath(projectFolder, "modpack/")
  tempPackFolder* = joinPath(projectFolder, "temppack/")
  overridesFolder* = joinPath(packFolder, "overrides/")
  paxFile* = joinPath(overridesFolder, ".pax")
  manifestFile* = joinPath(packFolder, "manifest.json")
  outputFolder* = joinPath(projectFolder, ".out/")

proc initManifestFile(projectId: int, fileId: int): ManifestFile =
  ## create a new manifest fmod object.
  result.projectId = projectId
  result.fileId = fileId

converter toManifestFile(json: JsonNode): ManifestFile =
  ## creates a ManifestFile from manifest json
  result.projectId = json["projectID"].getInt()
  result.fileId = json["fileID"].getInt()

converter toJson(file: ManifestFile): JsonNode {.used.} =
  ## creates the json for a manifest file `file`
  result = %* {
    "projectID": file.projectId,
    "fileID": file.fileId,
    "required": true
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
  manifest.files.sort((x,y) => cmp(x.projectId, y.projectId))
  result = %* {
    "minecraft": {
      "version": $manifest.mcVersion,
      "modLoaders": [{ "id": manifest.mcModloaderId, "primary": true }]
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

proc getFile*(manifest: Manifest, projectId: int): ManifestFile =
  ## returns the file with the provided `projectId`
  return manifest.files.filter((x) => x.projectId == projectId)[0]

proc installMod*(manifest: var Manifest, projectId: int, fileId: int): void =
  ## install a mod with the given `projectId` and `fileId`
  let file = initManifestFile(projectId, fileId)
  manifest.files = manifest.files & file

proc removeMod*(manifest: var Manifest, projectId: int): void =
  ## remove a mod from the project with the given `projectId`
  manifest.files.keepIf((x) => x.projectId != projectId)

proc updateMod*(manifest: var Manifest, projectId: int, fileId: int): void =
  ## update a mod with the given `projectId` to the given `fileId`
  removeMod(manifest, projectId)
  installMod(manifest, projectId, fileId)

template isPaxProject*: bool =
  ## returns true if the current folder is a pax project folder
  fileExists(manifestFile)

template requirePaxProject*: void =
  ## will error if the current folder isn't a pax project
  if not isPaxProject():
    echoError "The current folder isn't a pax project."
    styledEcho indentPrefix, "To initialize a pax project, enter ", fgRed, "pax init"
    return

template rejectPaxProject*: void =
  ## will error if the current folder is a pax project
  if isPaxProject:
    echoError "The current folder is already a pax project."
    styledEcho indentPrefix, "If you are sure you want to overwrite existing files, use the ", fgRed, "--force", resetStyle, " option"
    return

proc readManifestFromDisk*(path = manifestFile): Manifest =
  ## get a Manifest from disk (with `path` as the path)
  return readFile(path).parseJson.toManifest

proc writeToDisk*(manifest: Manifest, path = manifestFile): void =
  ## write `manifest` to disk (with `path` as the path)
  writeFile(path, manifest.toJson.pretty)