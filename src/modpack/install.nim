import options, sequtils
import files, loader, modinfo
import ../api/cf
import ../mc/version

type
  InstallStrategy* = enum
    ## Strategy when installing/updating mods.
    ## recommended =  newest version which is compatible with the modpack version.
    ## newest = newest version which is compatible with the minor modpack version.
    recommended, newest

converter toInstallStrategy*(str: string): InstallStrategy =
  ## Convert `str` to an InstallStrategy.
  case str:
    of "recommended": return InstallStrategy.recommended
    of "newest": return InstallStrategy.newest
    else: raise newException(ValueError, "cannot convert " & str & " to InstallStrategy")

proc isRecommendedMod(file: CfModFile, modpackVersion: Version): bool {.used.} =
  ## returns true if `file` is compatible according to InstallStrategy.recommended.
  return modpackVersion in file.gameVersions

proc isNewestMod(file: CfModFile, modpackVersion: Version): bool {.used.} =
  ## returns true if `file` is compatible according to InstallStrategy.newest.
  return modpackVersion.minor in file.gameVersions.map(minor)

proc selectModFile*(cfModFiles: seq[CfModFile], manifest: Manifest, strategy: InstallStrategy): Option[CfModFile] = 
  ## Select the best mod file out of `cfModFiles`, given the `manifest` and `strategy`.
  var latestFile = none[CfModFile]()
  for file in cfModFiles:
    let onFabric = manifest.loader == Loader.fabric and file.isFabricMod
    let onForge = manifest.loader == Loader.forge and file.isForgeMod
    let onRecommended = strategy == InstallStrategy.recommended and file.isRecommendedMod(manifest.mcVersion)
    let onNewest = strategy == InstallStrategy.newest and file.isNewestMod(manifest.mcVersion)
    if latestFile.isNone or latestFile.get().fileId < file.fileId:
      if onFabric or onForge:
        if onRecommended or onNewest:
          latestFile = some(file)
  
  if latestFile.isNone and strategy == InstallStrategy.recommended:
    return selectModFile(cfModFiles, manifest, InstallStrategy.newest)

  return latestFile