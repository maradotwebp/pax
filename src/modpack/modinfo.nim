## Computes information about an installed addon.
## 
## Some properties of an addon are tracked and shown to the user, like:
## - if the addon is up-to-date
## - if the addon is compatible with the modpack

import sequtils, sugar
import ../api/cfcore
import ../term/color
import ../modpack/version

type
  Compability* = enum
    ## compability of a mod version with the modpack version
    ## none = will not be compatible
    ## major = mod major version matches modpack major version, probably compatible
    ## full = mod version exactly matches modpack version, fully compatible
    None, Major, Full

  Freshness* = enum
    ## if an update to the currently installed version is available
    ## old = file is not the latest version for all gameversions
    ## newestForAVersion = file is the latest version for a gameversion
    ## newest = file is the newest version for the current modpack version
    Old, NewestForAVersion, Newest

const
  ## icon for compability
  compabilityIcon = "•"
  ## icon for freshness
  freshnessIcon = "↑"

proc getCompability*(file: CfAddonFile, modpackVersion: Version): Compability =
  ## get compability of a file
  if modpackVersion in file.gameVersions: return Compability.Full
  if modpackVersion.minor in file.gameVersions.proper.map(minor): return Compability.Major
  return Compability.None

proc getIcon*(c: Compability): TermOut =
  ## get the color for a compability
  case c:
    of Compability.Full: compabilityIcon.fgGreen
    of Compability.Major: compabilityIcon.fgYellow
    of Compability.None: compabilityIcon.fgRed

proc getMessage*(c: Compability): string =
  ## get the message for a certain compability
  case c:
    of Compability.Full: "The installed mod is compatible with the modpack's minecraft version."
    of Compability.Major: "The installed mod only matches the major version as the modpack. Issues may arise."
    of Compability.None: "The installed mod is incompatible with the modpack's minecraft version."

proc getFreshness*(file: CfAddonFile, modpackVersion: Version, addon: CfAddon): Freshness =
  ## get freshness of a file
  let latestFiles = addon.gameVersionLatestFiles
  let modpackVersionFiles = latestFiles.filter((x) => x.version == modpackVersion)
  if modpackVersionFiles.len == 1:
    if modpackVersionFiles[0].fileId == file.fileId:
      return Freshness.Newest
  if latestFiles.any((x) => x.fileId == file.fileId and x.version.minor == modpackVersion.minor):
    return Freshness.NewestForAVersion
  return Freshness.Old

proc getIcon*(f: Freshness): TermOut =
  ## get the color for a freshness
  case f:
    of Freshness.Newest: freshnessIcon.fgGreen
    of Freshness.NewestForAVersion: freshnessIcon.fgYellow
    of Freshness.Old: freshnessIcon.fgRed

proc getMessage*(f: Freshness): string =
  ## get the message for a certain freshness
  case f:
    of Freshness.Newest: "No mod updates available."
    of Freshness.NewestForAVersion: "Your installed version is newer than the recommended version. Issues may arise."
    of Freshness.Old: "There is a newer version of this mod available."