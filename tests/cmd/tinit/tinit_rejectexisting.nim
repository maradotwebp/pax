discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
  joinable: false
  batchable: false
  input: '''
y
  '''
"""

import os
import cmd/init

block:
  removeDir("./modpack")
  paxInit(force = false, skipManifest = true, skipGit = true)

  createDir("./modpack")
  writeFile("./modpack/manifest.json", "hello :D")
  defer: removeDir("./modpack")
  paxInit(force = false, skipManifest = true, skipGit = true)
  paxInit(force = true, skipManifest = true, skipGit = true)