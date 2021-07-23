import options, sequtils
import manifest, modinfo, mods
import ../modpack/loader, ../modpack/version

type
  InstallStrategy* = enum
    ## Strategy when installing/updating mods.
    ## stable = stable release (e.g. not alpha/beta) version compatible with the modpack version
    ## recommended = newest version which is compatible with the modpack version.
    ## newest = newest version which is compatible with the minor modpack version.
    stable, recommended, newest

converter toInstallStrategy*(str: string): InstallStrategy =
  ## Convert `str` to an InstallStrategy.
  case str:
    of "stable": return InstallStrategy.stable
    of "recommended": return InstallStrategy.recommended
    of "newest": return InstallStrategy.newest
    else: raise newException(ValueError, "cannot convert " & str & " to InstallStrategy")

proc isRecommendedMod(file: McModFile, modpackVersion: Version): bool {.used.} =
  ## returns true if `file` is compatible according to InstallStrategy.recommended.
  return modpackVersion in file.gameVersions

proc isStableMod(file: McModFile, modpackVersion: Version): bool {.used.} =
  ## returns true if `file` is compatible according to InstallStrategy.stable.
  return isRecommendedMod(file, modpackVersion) and file.releaseType == McModFileReleaseType.release

proc isNewestMod(file: McModFile, modpackVersion: Version): bool {.used.} =
  ## returns true if `file` is compatible according to InstallStrategy.newest.
  return modpackVersion.minor in file.gameVersions.map(minor)

proc selectModFile*(files: seq[McModFile], manifest: Manifest, strategy: InstallStrategy): Option[McModFile] = 
  ## Select the best mod file out of `files`, given the `manifest` and `strategy`.
  var latestFile = none[McModFile]()
  for file in files:
    let onFabric = manifest.loader == Loader.fabric and file.isFabricMod
    let onForge = manifest.loader == Loader.forge and file.isForgeMod
    let onStable = strategy == InstallStrategy.stable and file.isStableMod(manifest.mcVersion)
    let onRecommended = strategy == InstallStrategy.recommended and file.isRecommendedMod(manifest.mcVersion)
    let onNewest = strategy == InstallStrategy.newest and file.isNewestMod(manifest.mcVersion)
    if latestFile.isNone or latestFile.get().fileId < file.fileId:
      if onFabric or onForge:
        if onStable or onRecommended or onNewest:
          latestFile = some(file)
  
  if latestFile.isNone:
    return case strategy:
      of InstallStrategy.stable: selectModFile(files, manifest, InstallStrategy.recommended)
      of InstallStrategy.recommended: selectModFile(files, manifest, InstallStrategy.newest)
      else: latestFile

  return latestFile