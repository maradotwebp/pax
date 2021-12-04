## Defines methods for interacting with a curseforge manifest file.
## 
## In the CF modpack format, modpack information & mods/resourcepacks are tracked within
## a specific file known as the `manifest.json`. Each addon is tracked with a given projectid (identifies the addon)
## and a file id (identifies the version of the addon.)

import algorithm, asyncdispatch, json, options, os, sequtils, strformat, sugar
import loader
import ../api/cfclient, ../api/cfcore
import ../modpack/version
import ../term/color, ../term/log
export color
export log

type
  ManifestMetadata* = ref object
    ## Metadata for a given project in a manifest.json
    name*: string
    explicit*: bool
    pinned*: bool
    dependencies*: seq[int]

  ManifestFile* = ref object
    ## a file of a given project in a manifest.json.
    ## describes a specific version of a curseforge mod.
    projectId*: int
    fileId*: int
    metadata*: ManifestMetadata
    
  Manifest* = ref object
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
  gitIgnoreFile* = projectFolder / ".gitignore"
  gitIgnoreContent* = staticRead("templates/.gitignore")
  githubCiFolder* = projectFolder / ".github/workflows"
  githubCiFile* = githubCiFolder / "main.yml"
  githubCiContent* = staticRead("templates/main.yml")
  packFolder* = projectFolder / "modpack/"
  tempPackFolder* = projectFolder / "temppack/"
  overridesFolder* = packFolder / "overrides/"
  paxFile* = overridesFolder / ".pax"
  manifestFile* = packFolder / "manifest.json"
  outputFolder* = projectFolder / ".out/"

proc initManifestMetadata*(name: string, explicit: bool, pinned: bool, dependencies: seq[int]): ManifestMetadata =
  ## create a new manifest metadata object.
  result = ManifestMetadata()
  result.name = name
  result.explicit = explicit
  result.pinned = pinned
  result.dependencies = dependencies

proc initManifestFile*(projectId: int, fileId: int, metadata: ManifestMetadata): ManifestFile =
  ## create a new manifest fmod object.
  result = ManifestFile()
  result.projectId = projectId
  result.fileId = fileId
  result.metadata = metadata

proc toManifestFile(json: JsonNode): Future[ManifestFile] {.async.} =
  ## creates a ManifestFile from manifest json
  result = ManifestFile()
  result.projectId = json["projectID"].getInt()
  result.fileId = json["fileID"].getInt()
  result.metadata = ManifestMetadata()
  if json{"__meta"} == nil:
    let addon = fetchAddon(result.projectId)
    let addonFile = fetchAddonFile(result.projectId, result.fileId)
    await addon and addonFile
    if addon.read().isNone() or addonFile.read().isNone():
      raise newException(
        ValueError,
        fmt"projectID {result.projectId} & fileID {result.fileId} are not correct!"
      )
    result.metadata.name = addon.read().get().name
    result.metadata.explicit = true
    result.metadata.pinned = false
    result.metadata.dependencies = addonFile.read().get().dependencies
  else:
    result.metadata.name = json["__meta"]["name"].getStr()
    result.metadata.explicit = json["__meta"]{"explicit"}.getBool(true)
    result.metadata.pinned = json["__meta"]{"pinned"}.getBool(false)
    result.metadata.dependencies = json["__meta"]{"dependencies"}.getElems(@[]).map((x) => x.getInt())

converter toJson(file: ManifestFile): JsonNode {.used.} =
  ## creates the json for a manifest file `file`
  result = %* {
    "projectID": file.projectId,
    "fileID": file.fileId,
    "required": true,
    "__meta": {
      "name": file.metadata.name
    }
  }
  if not file.metadata.explicit:
    result["__meta"]["explicit"] = newJBool(false)
  if file.metadata.pinned:
    result["__meta"]["pinned"] = newJBool(true)
  if file.metadata.dependencies.len > 0:
    let dependencyJsonArray = newJArray()
    for d in file.metadata.dependencies:
      dependencyJsonArray.add(newJInt(d))
    result["__meta"]["dependencies"] = dependencyJsonArray

converter toManifest(json: JsonNode): Manifest =
  ## creates a Manifest from manifest json
  result = Manifest()
  result.name = json["name"].getStr()
  result.author = json{"author"}.getStr()
  result.version = json{"version"}.getStr()
  result.mcVersion = json["minecraft"]["version"].getStr().Version
  result.mcModloaderId = json["minecraft"]["modLoaders"][0]["id"].getStr()
  let fileElemRequests = json["files"].getElems().map(toManifestFile)
  let files = waitFor(all(fileElemRequests))
  result.files = files

converter toJson*(manifest: Manifest): JsonNode =
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

proc getDependents*(manifest: Manifest, projectId: int): seq[ManifestFile] =
  ## returns the dependents of the mod associated with projectId
  return manifest.files.filter((file) => file.metadata.dependencies.any((d) => d == projectId))

proc getFile*(manifest: Manifest, projectId: int): ManifestFile =
  ## returns the file with the provided `projectId`
  return manifest.files.filter((x) => x.projectId == projectId)[0]

proc installAddon*(manifest: var Manifest, file: ManifestFile): void =
  ## install an addon with a given ManifestFile
  manifest.files = manifest.files & file

proc removeAddon*(manifest: var Manifest, projectId: int): ManifestFile =
  ## remove a mod from the project with the given `projectId`, returns removed mod.
  for i, file in manifest.files:
    if file.projectId == projectId:
      manifest.files.delete(i, i)
      return file

proc updateAddon*(manifest: var Manifest, file: ManifestFile): void =
  ## update a mod with the given `file`
  discard removeAddon(manifest, file.projectId)
  installAddon(manifest, file)

proc updateAddon*(manifest: var Manifest, projectId: int, fileId: int): void =
  ## update a mod with the given `projectId` to the given `fileId`
  var modToUpdate = removeAddon(manifest, projectId)
  modToUpdate.fileId = fileId
  installAddon(manifest, modToUpdate)

template isPaxProject*: bool =
  ## returns true if the current folder is a pax project folder
  fileExists(manifestFile)

template requirePaxProject*: void =
  ## will error if the current folder isn't a pax project
  if not isPaxProject():
    echoError "The current folder isn't a pax project."
    echoClr indentPrefix, "To initialize a pax project, enter ".fgRed, "pax init"
    return

template rejectPaxProject*: void =
  ## will error if the current folder is a pax project
  if isPaxProject:
    echoError "The current folder is already a pax project."
    echoClr indentPrefix, "If you are sure you want to overwrite existing files, use the ", "--force".fgRed, " option"
    return

template rejectInstalledAddon*(manifest: Manifest, projectId: int): void =
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
