# Package

version       = "2.0.0"
author        = "froehlichA"
description   = "a minecraft modpack development manager"
license       = "MIT"
srcDir        = "src"
bin           = @["pax"]



# Dependencies

requires "nim >= 1.4.6"
requires "regex >= 0.19.0"
requires "therapist >= 0.2.0"
requires "zippy >= 0.6.2"

task test, "Test project":
    exec "testament all"

task buildDev, "Build for usage during development":
    exec "nimble build -d:ssl"

task buildProd, "Build for production":
    exec "nimble build -d:ssl -d:release"

task buildCI, "Build for production on the CI machine":
    exec "nimble build -d:ssl -d:release -y"