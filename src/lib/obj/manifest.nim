import sequtils, json

type
  ManifestFile* = object
    ## A file of a given project in a manifest.json.
    ## Describes a specific version of a curseforge mod.
    projectId*: int
    fileId*: int

  ManifestProject* = object
    ## A project in a manifest.json.
    ## Describes the modpack.
    name*: string
    author*: string
    version*: string
    mcVersion*: string
    mcModloaderId*: string
    files*: seq[ManifestFile]

proc initManifestFile*(projectId: int, fileId: int): ManifestFile =
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
  result = %* {
    "minecraft": {
      "version": project.mcVersion,
      "modLoaders": [{ "id": project.mcModloaderId, "primary": true }]
    },
    "manifestType": "minecraftModpack",
    "overrides": "overrides",
    "manifestVersion": 1,
    "version": project.version,
    "author": project.author,
    "name": project.name,
    "files": project.files.map(toJson)
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
  result.mcVersion = json["minecraft"]["version"].getStr()
  result.mcModloaderId = json["minecraft"]["modLoaders"][0]["id"].getStr()
  result.files = json["files"].getElems().map(fileFromJson)