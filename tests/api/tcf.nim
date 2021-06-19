discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import asyncdispatch, api/cf, sequtils, sugar

block: # fetch by query
  let mods = waitFor(fetchModsByQuery("jei"))
  doAssert mods[0].projectId == 238222
  doAssert mods[0].name == "Just Enough Items (JEI)"

block: # fetch mod by id
  let cfMod = waitFor(fetchMod(220318))
  doAssert cfMod.projectId == 220318
  doAssert cfMod.name == "Biomes O' Plenty"

blocK: # fetch mod by slug
  let cfMod = waitFor(fetchMod("appleskin"))
  doAssert cfMod.projectId == 248787

block: # fetch mod files
  let modFiles = waitFor(fetchModFiles(248787))
  doAssert modFiles.any((x) => x.fileId == 3035787)

block: # fetch mod file
  let modFile = waitFor(fetchModFile(306770, 2992184))
  doAssert modFile.fileId == 2992184
  doAssert modFile.name == "Patchouli-1.0-21.jar"
