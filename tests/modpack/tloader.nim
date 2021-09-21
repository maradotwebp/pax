import modpack/loader

block: # loader
  doAssert "forge-43.1.0".toLoader == Loader.Forge
  doAssert "fabric-0.11.0".toLoader == Loader.Fabric
  doAssert "forge-something-something".toLoader == Loader.Forge

  doAssert "forge" == Loader.Forge.`$`
  doAssert "fabric" == Loader.Fabric.`$`