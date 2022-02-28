discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import asyncdispatch, options, sequtils, strutils, sugar
import api/cfclient, api/cfcore

block: # fetch by query
  let mods = waitFor(fetchAddonsByQuery("jei"))
  doAssert mods[0].projectId == 238222
  doAssert mods[0].name == "Just Enough Items (JEI)"

block: # fetch mods by query
  let mods = waitFor(fetchAddonsByQuery("jei", some(CfAddonGameCategory.Mod)))
  doAssert mods.all(m => m.websiteUrl.contains("/mc-mods/"))

block: # fetch resource packs  by query
  let mods = waitFor(fetchAddonsByQuery("jei", some(CfAddonGameCategory.Resourcepack)))
  doAssert mods.all(m => m.websiteUrl.contains("/texture-packs/"))

block: # fetch mod by id
  let mcMod = waitFor(fetchAddon(220318)).get()
  doAssert mcMod.projectId == 220318
  doAssert mcMod.name == "Biomes O' Plenty"

## Skip failing test because the curse.nikky.moe api doesn't update anymore
#[
block: # fetch mod by slug
  var mcMod = waitFor(fetchAddon("appleskin")).get()
  doAssert mcMod.projectId == 248787
  mcMod = waitFor(fetchAddon("dtbop")).get()
  doAssert mcMod.projectId == 289529
  mcMod = waitFor(fetchAddon("dtphc")).get()
  doAssert mcMod.projectId == 307560
]#

block: # fetch mod files
  let modFiles = waitFor(fetchAddonFiles(248787))
  doAssert modFiles.any((x) => x.fileId == 3035787)

block: # fetch mod file
  let modFile = waitFor(fetchAddonFile(306770, 2992184)).get()
  doAssert modFile.fileId == 2992184
  doAssert modFile.name == "Patchouli-1.0-21.jar"

block: # check if dependencies are tracked
  let modFile = waitFor(fetchAddonFile(243121, 3366626)).get()
  doAssert modFile.dependencies == @[250363]
