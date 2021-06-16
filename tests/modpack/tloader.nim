discard """"""

import modpack/loader

block: # loader
  doAssert "forge-43.1.0".toLoader == Loader.forge
  doAssert "fabric-0.11.0".toLoader == Loader.fabric
  doAssert "forge-something-something".toLoader == Loader.forge

  doAssert "forge" == Loader.forge.toString
  doAssert "fabric" == Loader.fabric.toString