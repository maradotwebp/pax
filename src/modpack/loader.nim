## Exports `Loader` which specifies the modloader type for a given modpack.
## 
## Pax currently has support for the Fabric & Forge modloaders and assumes that mods that work on one modloader
## do not work on another.

import strformat, strutils

type
  Loader* = enum
    Fabric, Forge

converter toLoader*(str: string): Loader =
  ## cast a string to a Loader.
  let str = str.toLower
  return
    if str.contains("forge"): Loader.Forge
    elif str.contains("fabric"): Loader.Fabric
    else: raise newException(ValueError, fmt"'{str}' is not a loader")

proc `$`*(loader: Loader): string =
  return case loader:
    of Loader.Forge: "forge"
    of Loader.Fabric: "fabric"