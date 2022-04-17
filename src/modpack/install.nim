## Helper methods to select a version from a mod to install.
## 
## Users of Pax can choose between three different strategies which decide how the "best" version
## of a mod to install is selected.

import std/sequtils
import ../api/cfcore
import ../modpack/[loader, version]

type
  InstallStrategy* = enum
    ## Strategy when installing/updating mods.
    ## stable = stable release (e.g. not alpha/beta) version compatible with the modpack version
    ## recommended = newest version which is compatible with the modpack version.
    ## newest = newest version which is compatible with the minor modpack version.
    Stable, Recommended, Newest

  PaxInstallError* = object of IOError

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

proc selectAddonFile*(files: seq[CfAddonFile], mpLoader: Loader, mpMcVersion: Version, strategy: InstallStrategy): CfAddonFile = 
  ## Select the best mod file out of `files`, given the `manifest` and `strategy`.
  for file in files:
    if result.isNil or result.fileId < file.fileId:
      let onFabric = mpLoader == Loader.Fabric and file.isFabricCompatible
      let onForge = mpLoader == Loader.Forge and file.isForgeCompatible
      let onStable = strategy == InstallStrategy.Stable and file.isStable(mpMcVersion)
      let onRecommended = strategy == InstallStrategy.Recommended and file.isRecommended(mpMcVersion)
      let onNewest = strategy == InstallStrategy.Newest and file.isNewest(mpMcVersion)
      if onFabric or onForge:
        if onStable or onRecommended or onNewest:
          result = file
  
  # In case nothing has been found, fallback to more generous install strategies
  if result.isNil:
    case strategy:
      of InstallStrategy.Stable:
        return selectAddonFile(files, mpLoader, mpMcVersion, InstallStrategy.Recommended)
      of InstallStrategy.Recommended:
        return selectAddonFile(files, mpLoader, mpMcVersion, InstallStrategy.Newest)
      else:
        raise newException(PaxInstallError, "No suitable version found for file '" & files[0].name & "'.")