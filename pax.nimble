# Package

version       = "0.1.0"
author        = "froehlichA"
description   = "modpack development manager for minecraft"
license       = "MIT"
srcDir        = "src"
bin           = @["pax"]



# Dependencies

requires "nim >= 1.2.0"
requires "cligen >= 1.3.2"
requires "zip >= 0.3.1"

task buildDev, "Build for usage during development":
    exec "nimble build -d:ssl"

task buildProd, "Build for production":
    exec "nimble build -d:ssl -d:release"
