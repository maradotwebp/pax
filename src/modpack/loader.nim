import strutils

type
  Loader* = enum
    ## the loader used for a modpack.
    ## mods may be compatible with one or both of them.
    fabric, forge

converter toLoader*(str: string): Loader =
  ## get the loader from `str`
  let str = str.toLower
  if str.contains("forge"):
    return Loader.forge
  elif str.contains("fabric"):
    return Loader.fabric
  else:
    raise newException(ValueError, "incorrect loader string")

converter toString*(loader: Loader): string =
  ## get a string from `loader`
  return $loader