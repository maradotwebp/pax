## Defines several common functions for working with minecraft versions, such as
## equality checking & comparisons to check whether a version is older or newer than another one.

import hashes, sequtils, strutils, sugar

type
  ## A minecraft version (1.11, 1.12.2, 1.16.4, 1.14.1, ...)
  ## in $major.$minor or $major.$minor.$patch form.
  ## May contain alternative-style versions (1.16-Snapshot)
  ## or the values "Forge" or "Fabric".
  Version* = distinct string

proc `$`*(v: Version): string {.borrow.}
proc `==`*(v1: Version, v2: Version): bool {.borrow.}
proc hash*(x: Version): Hash = hash($x)

proc minor*(v: Version): Version =
  ## get the minor part of a version. "1.16.4" -> "1.14"
  ## will return the string if it doesn't match semver
  let parts = ($v).split('.')
  # if it's a snapshot string (for example "1.16-Snapshot"), just remove "-Snapshot" to get "1.16"
  if parts.len > 1 and parts[1].contains("-Snapshot"): return Version(parts[0] & "." & parts[1].replace("-Snapshot"))
  # if it's $major.$minor already, nice, return directly
  if parts.len == 2: return v
  # if not $major.$minor.$patch, probably some other format, better return directly
  if parts.len != 3: return v
  # if format's good, just join the first 2 parts
  return Version(parts[0] & "." & parts[1])

proc `>`*(v1: Version, v2: Version): bool =
  ## compares two versions
  let v1Parts = ($v1).split('.')
  let v2Parts = ($v2).split('.')
  # Snapshots
  if v1Parts.len == 2 and v1Parts[1].contains("-Snapshot"):
    if v1.minor == v2.minor: return false
    return v1Parts[1].replace("-Snapshot").parseInt > v2Parts[1].replace("-Snapshot").parseInt
  if v2Parts.len == 2 and v2Parts[1].contains("-Snapshot"):
    if v1.minor == v2.minor: return true
    return v1Parts[1].replace("-Snapshot").parseInt > v2Parts[1].replace("-Snapshot").parseInt
  # 1.16.4 > 1.16
  if v1Parts.len == 2 or v2Parts.len == 2: return v1Parts[1].parseInt > v2Parts[1].parseInt
  # match by minor version first, then by patch
  if v1Parts[1].parseInt == v2Parts[1].parseInt: return v1Parts[2].parseInt > v2Parts[2].parseInt
  return v1Parts[1].parseInt > v2Parts[1].parseInt

proc `<`*(v1: Version, v2: Version): bool = v2 > v1
proc `>=`*(v1: Version, v2: Version): bool = v1 > v2 or v1 == v2
proc `<=`*(v1: Version, v2: Version): bool = v1 < v2 or v1 == v2

proc proper*(v: seq[Version]): seq[Version] =
  ## filter out "Forge" and "Fabric" values
  return v.filter((x) => x != "Forge".Version and x != "Fabric".Version)