discard """
  joinable: false
  batchable: false
"""

import std/[os, tempfiles]
import modpack/[loader, manifest, version]

block: # rejectInstalledAddon
  let m = Manifest()
  m.name = "testmodpack"
  m.author = "testauthor"
  m.version = "1.0.0"
  m.mcVersion = "1.16.3".Version
  m.files = @[ManifestFile(projectId: 1234, fileId: 100)]

  let f = proc(projectId: int): int =
    result = -1
    m.rejectInstalledAddon(projectId)
    result = 1

  doAssert f(1234) == -1
  doAssert f(9999) == 1

block: # isPaxProject
  let tmpdir = createTempDir("tmanifest_templates_isPaxProject", "")

  doAssert isPaxProject(tmpdir) == false
  writeFile(tmpdir / "manifest.json", "")
  doAssert isPaxProject(tmpdir) == true

block: # requirePaxProject
  let tmpdir = createTempDir("tmanifest_templates_requirePaxProject", "")
  let f = proc(): int =
    result = -1
    requirePaxProject(tmpdir)
    result = 1

  doAssert f() == -1
  writeFile(tmpdir / "manifest.json", "")
  doAssert f() == 1

block: # rejectPaxProject
  let tmpdir = createTempDir("tmanifest_templates_rejectPaxProject", "")
  let f = proc(): int =
    result = -1
    rejectPaxProject(tmpdir)
    result = 1

  doAssert f() == 1
  writeFile(tmpdir / "manifest.json", "")
  doAssert f() == -1