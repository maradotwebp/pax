import algorithm, sequtils, strutils, sugar, json, version

type
  Loader* = enum
    ## the loader used for a modpack.
    ## mods may be compatible with one or both of them.
    fabric, forge

  ManifestFile* = object
    ## a file of a given project in a manifest.json.
    ## describes a specific version of a curseforge mod.
    projectId*: int
    fileId*: int

  ManifestProject* = object
    ## a project in a manifest.json.
    ## describes the modpack.
    name*: string
    author*: string
    version*: string
    mcVersion*: Version
    mcModloaderId*: string
    files*: seq[ManifestFile]

proc initManifestFile*(projectId: int, fileId: int): ManifestFile =
  ## create a new manifest file object.
  result.projectId = projectId
  result.fileId = fileId

proc toJson*(file: ManifestFile): JsonNode =
  ## creates the json for a manifest from a file
  result = %* {
    "projectID": file.projectId,
    "fileID": file.fileId,
    "required": true
  }

proc toJson*(project: ManifestProject): JsonNode =
  ## creates the json for a manifest from a project
  var p = project
  p.files.sort(proc(x, y: ManifestFile): int = cmp(x.projectId, y.projectId))
  result = %* {
    "minecraft": {
      "version": $p.mcVersion,
      "modLoaders": [{ "id": p.mcModloaderId, "primary": true }]
    },
    "manifestType": "minecraftModpack",
    "overrides": "overrides",
    "manifestVersion": 1,
    "version": p.version,
    "author": p.author,
    "name": p.name,
    "files": p.files.map(toJson)
  }

proc fileFromJson*(json: JsonNode): ManifestFile =
  ## creates a file object from manifest json
  result.projectId = json["projectID"].getInt()
  result.fileId = json["fileID"].getInt() 

proc projectFromJson*(json: JsonNode): ManifestProject =
  ## creates a project object from manifest json
  result.name = json["name"].getStr()
  result.author = json["author"].getStr()
  result.version = json["version"].getStr()
  result.mcVersion = json["minecraft"]["version"].getStr().Version
  result.mcModloaderId = json["minecraft"]["modLoaders"][0]["id"].getStr()
  result.files = newSeq[ManifestFile]()
  for jsonFile in json["files"].getElems():
    let file = jsonFile.fileFromJson
    result.files.add(file)

proc toLoader*(str: string): Loader =
  return if str.contains("forge"): Loader.forge else: Loader.fabric

proc loader*(project: ManifestProject): Loader =
  ## returns the loader (either Fabric or Forge)
  return project.mcModloaderId.toLoader

proc isInstalled*(project: ManifestProject, projectId: int): bool =
  ## returns true if the ManifestFile with the given projectId is installed
  return projectId in project.files.map((x) => x.projectId)

proc getFile*(project: ManifestProject, projectId: int): ManifestFile =
  ## returns the file with the provided projectId
  return project.files.filter((x) => x.projectId == projectId)[0]

proc installMod*(project: var ManifestProject, projectId: int, fileId: int): void =
  ## install a mod into the project
  let file = initManifestFile(projectId, fileId)
  project.files = project.files & file

proc removeMod*(project: var ManifestProject, projectId: int): void =
  ## remove a mod from the project
  keepIf(project.files, proc(f: ManifestFile): bool =
    f.projectId != projectId
  )

proc updateMod*(project: var ManifestProject, projectId: int, fileId: int): void =
  ## update a mod in the project
  removeMod(project, projectId)
  installMod(project, projectId, fileId)