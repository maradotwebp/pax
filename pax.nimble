# Package

version       = "2.0.0"
author        = "mara.webp"
description   = "a minecraft modpack development manager"
license       = "MIT"
srcDir        = "src"
bin           = @["pax"]



# Dependencies

requires "nim >= 1.6.4"
requires "regex >= 0.19.0"
requires "therapist >= 0.3.0"
requires "zippy >= 0.6.2"

task test, "Test project":
    exec "testament all"
