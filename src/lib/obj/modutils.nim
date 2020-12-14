import sequtils, strutils, tables
import mods

type
    Compability* = enum
        ## compability of a mod version with the modpack version
        ## none = will not be compatible
        ## major = mod major version matches modpack major version, probably compatible
        ## full = mod version exactly matches modpack version, fully compatible
        none, major, full

    Freshness* = enum
        ## if an update to the currently installed version is available
        ## old = file is not the latest version for all gameversions
        ## newestForAVersion = file is the latest version for a gameversion
        ## newest = file is the newest version for the current modpack version
        old, newestForAVersion, newest

proc getMajorVersion(version: string): string =
    ## get the major version of a version. "1.16.4" -> "1.14"
    ## will return the string if it doesn't match semver
    let parts = version.split('.')
    if parts.len > 1 and parts[1].contains("-Snapshot"):
        # a snapshot string "1.16-Snapshot"
        return parts[0] & "." & parts[1].replace("-Snapshot")
    if parts.len != 3:
        # probably some other format, better return format
        return version
    return parts[0] & "." & parts[1]

proc getFileCompability*(file: McModFile, version: string): Compability =
    ## compability of a file with the modpack version
    if version in file.gameVersions: return Compability.full
    if getMajorVersion(version) in file.gameVersions.map(getMajorVersion): return Compability.major
    return Compability.none

proc getFileFreshness*(file: McModFile, version: string, mcMod: McMod): Freshness =
    ## freshness of a file with the modpack
    let versionFiles = mcMod.gameVersionLatestFiles
    if versionFiles.hasKey(version) and versionFiles[version] == file.fileId: return Freshness.newest
    for ver in versionFiles.values:
        if file.fileId == ver:
            if versionFiles.hasKey(version):
                return Freshness.newestForAVersion
            else:
                return Freshness.newest
    return Freshness.old

proc isLatestFileForVersion*(file: McModFile, version: string, gameVersionLatestFiles: Table[string, int]): bool =
    ## returns true if file is the latest available version for that gameversion
    return gameVersionLatestFiles[version] == file.fileId