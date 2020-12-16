import sequtils, strutils, tables
import mods, ../io/term

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

proc laterVersionThan*(v1: string, v2: string): bool =
    ## returns true if v1 is a later version than v2
    let parts1 = v1.split('.')
    let parts2 = v2.split('.')
    if parts1.len > 1 and parts1[1].contains("-Snapshot"):
        return false
    if parts2.len > 1 and parts2[1].contains("-Snapshot"):
        return true
    if parts1.len < 3 or parts2.len < 3:
        return parts1.len > parts2.len
    if parts1[2].parseInt == parts2[2].parseInt:
        return parts1[1].parseInt > parts2[1].parseInt
    return parts1[2].parseInt > parts2[2].parseInt

proc getMajorVersion*(version: string): string =
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

proc getIcon*(c: Compability): string =
    case c:
        of Compability.full: "•".clrGreen
        of Compability.major: "•".clrYellow
        of Compability.none: "•".clrRed

proc getMessage*(c: Compability): string =
    case c:
        of Compability.full: "•".clrGreen & " The installed mod is compatible with the modpack's minecraft version."
        of Compability.major: "•".clrYellow & " The installed mod only matches the major version as the modpack. Issues may arise."
        of Compability.none: "•".clrRed & " The installed mod is incompatible with the modpack's minecraft version."

proc getFileFreshness*(file: McModFile, version: string, mcMod: McMod): Freshness =
    ## freshness of a file with the modpack
    let versionFiles = mcMod.gameVersionLatestFiles
    if versionFiles.hasKey(version) and versionFiles[version] == file.fileId: return Freshness.newest
    for ver in versionFiles.values:
        if file.fileId == ver:
            if versionFiles.hasKey(version):
                if any(file.gameVersions, proc(fileVer: string): bool = fileVer.laterVersionThan(version)):
                    return Freshness.newestForAVersion
            else:
                return Freshness.newest
    return Freshness.old

proc getIcon*(f: Freshness): string =
    case f:
        of Freshness.newest: "↑".clrGreen
        of Freshness.newestForAVersion: "↑".clrYellow
        of Freshness.old: "↑".clrRed

proc getMessage*(f: Freshness): string =
    case f:
        of Freshness.newest: "↑".clrGreen & " No mod updates available."
        of Freshness.newestForAVersion: "↑".clrYellow & " Your installed version is newer than the recommended version. Issues may arise."
        of Freshness.old: "↑".clrRed & " There is a newer version of this mod available."

proc isLatestFileForVersion*(file: McModFile, version: string, gameVersionLatestFiles: Table[string, int]): bool =
    ## returns true if file is the latest available version for that gameversion
    return gameVersionLatestFiles[version] == file.fileId