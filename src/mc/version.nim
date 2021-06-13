import hashes, sequtils, strutils, options

type
  ## A minecraft version (1.12.2, 1.16.4, 1.14.1, ...)
  ## May contain alternative-style versions (1.16-Snapshot)
  Version* = distinct string

proc `$`*(v: Version): string {.borrow.}
proc `==`*(v1: Version, v2: Version): bool {.borrow.}

proc hash*(x: Version): Hash = ($x).hash

proc `>`*(v1: Version, v2: Version): bool =
  ## compares two versions
  let v1Parts = ($v1).split('.')
  let v2Parts = ($v2).split('.')
  # Snapshots
  if v1Parts.len == 2 and v1Parts[1].contains("-Snapshot"): return false
  if v2Parts.len == 2 and v2Parts[1].contains("-Snapshot"): return true
  # 1.16.4 > 1.16
  if v1Parts.len == 2 or v2Parts.len == 2: return v1Parts[1].parseInt > v2Parts[1].parseInt
  # match by minor version first, then by patch
  if v1Parts[1].parseInt == v2Parts[1].parseInt: return v1Parts[2].parseInt > v2Parts[2].parseInt
  return v1Parts[1].parseInt > v2Parts[1].parseInt

proc minor*(v: Version): string =
  ## get the minor part of a version. "1.16.4" -> "1.14"
  ## will return the string if it doesn't match semver
  let parts = ($v).split('.')
  # if it's a snapshot string "1.16-Snapshot", just remove "-Snapshot" to get "1.16"
  if parts.len > 1 and parts[1].contains("-Snapshot"): return parts[0] & "." & parts[1].replace("-Snapshot")
  # probably some other format, better return directly
  if parts.len != 3: return $v
  # if format's good, just join the first 2 parts
  return parts[0] & "." & parts[1]

proc newest*(v: seq[Version], match: Version): Option[Version] =
  ## get the newest version from a sequence that is compatible with match
  result = none(Version)
  for item in v:
    if result.isNone:
      if minor(item) == minor(match):
        result = some(item)
    if result.isSome:
      if item > result.get() and minor(item) == minor(match):
        result = some(item)

proc proper*(v: seq[Version]): seq[Version] =
  ## only return proper versions
  return v.filter(proc(x: Version): bool = x != "Forge".Version and x != "Fabric".Version)