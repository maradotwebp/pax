import sequtils, sugar, tables
import mods, verutils
import ../io/term

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


proc getFileCompability*(file: McModFile, version: Version): Compability =
    ## compability of a file with the modpack version
    if version in file.gameVersions: return Compability.full
    if version.minor in file.gameVersions.properVersions.map(minor): return Compability.major
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

proc getFileFreshness*(file: McModFile, version: Version, mcMod: McMod): Freshness =
    ## freshness of a file with the modpack
    let versionFiles = mcMod.gameVersionLatestFiles
    if versionFiles.hasKey(version) and versionFiles[version] == file.fileId: return Freshness.newest
    for ver in versionFiles.values:
        if file.fileId == ver:
            if versionFiles.hasKey(version):
                if any(file.gameVersions.properVersions, (it) => it > version):
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