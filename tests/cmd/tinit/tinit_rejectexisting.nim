discard """
    joinable: false
  batchable: false
  input: '''
y
  '''
"""

import std/os
import cmd/init

block:
  removeDir("./modpack")
  paxInit(force = false, skipManifest = true, skipGit = true)

  createDir("./modpack")
  writeFile("./modpack/manifest.json", "hello :D")
  defer: removeDir("./modpack")
  paxInit(force = false, skipManifest = true, skipGit = true)
  paxInit(force = true, skipManifest = true, skipGit = true)