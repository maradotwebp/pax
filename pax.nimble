# Package

version       = "0.1.0"
author        = "froehlichA"
description   = "modpack development manager for minecraft"
license       = "MIT"
srcDir        = "src"
bin           = @["pax"]



# Dependencies

requires "nim >= 1.2.0"
requires "regex >= 0.19.0"
requires "therapist >= 0.2.0"
requires "zippy >= 0.5.10"

task test, "Test project":
    exec "testament pattern \"tests/**/*.nim\""

task buildDev, "Build for usage during development":
    exec "nimble build -d:ssl"

task buildProd, "Build for production":
    exec "nimble build -d:ssl -d:release"
