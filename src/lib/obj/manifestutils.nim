import sequtils, sugar
import manifest

proc isInstalled*(project: ManifestProject, projectId: int): bool =
  ## returns true if the ManifestFile with the given projectId is installed
  return projectId in project.files.map((x) => x.projectId)

proc getFile*(project: ManifestProject, projectId: int): ManifestFile =
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