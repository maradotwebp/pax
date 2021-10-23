## Helper methods to select a version from a mod to install.
## 
## Users of Pax can choose between three different strategies which decide how the "best" version
## of a mod to install is selected.

import options, sequtils
import manifest
import ../api/cfcore
import ../modpack/loader, ../modpack/version

type
  InstallStrategy* = enum
    ## Strategy when installing/updating mods.
    ## stable = stable release (e.g. not alpha/beta) version compatible with the modpack version
    ## recommended = newest version which is compatible with the modpack version.
    ## newest = newest version which is compatible with the minor modpack version.
    Stable, Recommended, Newest

converter toInstallStrategy*(str: string): InstallStrategy =
  ## Convert `str` to an InstallStrategy.
  case str:
    of "stable": return InstallStrategy.Stable
    of "recommended": return InstallStrategy.Recommended
    of "newest": return InstallStrategy.Newest
    else: raise newException(ValueError, "cannot convert " & str & " to InstallStrategy")

proc isRecommended(file: CfAddonFile, modpackVersion: Version): bool =
  ## returns true if `file` is compatible according to InstallStrategy.recommended.
  return modpackVersion in file.gameVersions

proc isStable(file: CfAddonFile, modpackVersion: Version): bool =
  ## returns true if `file` is compatible according to InstallStrategy.stable.
  return isRecommended(file, modpackVersion) and file.releaseType == CfAddonFileReleaseType.Release

proc isNewest(file: CfAddonFile, modpackVersion: Version): bool =
  ## returns true if `file` is compatible according to InstallStrategy.newest.
  return modpackVersion.minor in file.gameVersions.map(minor)

proc selectAddonFile*(files: seq[CfAddonFile], manifest: Manifest, strategy: InstallStrategy): Option[CfAddonFile] = 
  ## Select the best mod file out of `files`, given the `manifest` and `strategy`.
  var latestFile = none[CfAddonFile]()
  for file in files:
    let onFabric = manifest.loader == Loader.Fabric and file.isFabricCompatible
    let onForge = manifest.loader == Loader.Forge and file.isForgeCompatible
    let onStable = strategy == InstallStrategy.Stable and file.isStable(manifest.mcVersion)
    let onRecommended = strategy == InstallStrategy.Recommended and file.isRecommended(manifest.mcVersion)
    let onNewest = strategy == InstallStrategy.Newest and file.isNewest(manifest.mcVersion)
    if latestFile.isNone or latestFile.get().fileId < file.fileId:
      if onFabric or onForge:
        if onStable or onRecommended or onNewest:
          latestFile = some(file)
  
  if latestFile.isNone:
    return case strategy:
      of InstallStrategy.Stable: selectAddonFile(files, manifest, InstallStrategy.Recommended)
      of InstallStrategy.Recommended: selectAddonFile(files, manifest, InstallStrategy.Newest)
      else: latestFile

  return latestFile