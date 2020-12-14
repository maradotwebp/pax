import sequtils, strutils, tables
import mods

type
    Compability* = enum
        ## compability of a mod version with the modpack version
        ## none = will not be compatible
        ## major = mod major version matches modpack major version, probably compatible
        ## full = mod version exactly matches modpack version, fully compatible
        none, major, full

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

proc getVersionCompability*(file: McModFile, version: string): Compability =
    ## compability of a file with the modpack version
    if version in file.gameVersions: return Compability.full
    if getMajorVersion(version) in file.gameVersions.map(getMajorVersion): return Compability.major
    return Compability.none

proc isLatestFileForVersion*(file: McModFile, version: string, gameVersionLatestFiles: Table[string, int]): bool =
    ## returns true if file is the latest available version for that gameversion
    return gameVersionLatestFiles[version] == file.fileId