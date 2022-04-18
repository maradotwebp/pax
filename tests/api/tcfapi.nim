import std/[asyncdispatch, options, sequtils, strutils, sugar]
import api/[cfapi, cfcore]
import ../tutils

asyncBlock: # fetch by query
  let mods = await fetchAddonsByQuery("jei")
  doAssert mods[0].projectId == 238222
  doAssert mods[0].name == "Just Enough Items (JEI)"

asyncBlock: # fetch mods by query
  let mods = await fetchAddonsByQuery("jei", some(CfAddonGameCategory.Mod))
  doAssert mods.all(m => m.websiteUrl.contains("/mc-mods/"))

asyncBlock: # fetch resource packs by query
  let mods = await fetchAddonsByQuery("jei", some(CfAddonGameCategory.Resourcepack))
  doAssert mods.all(m => m.websiteUrl.contains("/texture-packs/"))

asyncBlock: # fetch non-existing by query
  let mods = await fetchAddonsByQuery("---------------------------")
  doAssert mods.len == 0

asyncBlock: # fetch mod by id
  let mcMod = await fetchAddon(220318)
  doAssert mcMod.projectId == 220318
  doAssert mcMod.name == "Biomes O' Plenty"

asyncBlock: # fetch mod by non-existing id
  doAssertRaises(CfApiError):
    discard await fetchAddon(99999999)

asyncBlock: # fetch mods by id
  let mcMods = await fetchAddons(@[220318, 238222])
  doAssert mcMods[0].projectId == 220318
  doAssert mcMods[1].projectId == 238222

asyncBlock: # fetch mods by non-existing id
  doAssertRaises(CfApiError):
    discard await fetchAddons(@[220318, 99999999])

asyncBlock: # fetch mod by slug
  var mcMod = await fetchAddon("appleskin")
  doAssert mcMod.projectId == 248787
  mcMod = await fetchAddon("dtbop")
  doAssert mcMod.projectId == 289529
  mcMod = await fetchAddon("dtphc")
  doAssert mcMod.projectId == 307560

asyncBlock: # fetch mod by non-existing slug
  doAssertRaises(CfApiError):
    discard await fetchAddon("abcdefghijklmnopqrstuvwxyz")

asyncBlock: # fetch mod files by project id
  let modFiles = await fetchAddonFiles(248787)
  doAssert modFiles.any((x) => x.fileId == 3035787)

asyncBlock: # fetch mod files by non-existing project id
  doAssertRaises(CfApiError):
    discard await fetchAddonFiles(99999999)

asyncBlock: # fetch mod files by file ids
  let modFiles = await fetchAddonFiles(@[2992184, 3098571])
  doAssert modFiles[0].fileId == 2992184
  doAssert modFiles[1].fileId == 3098571

asyncBlock: # fetch mod files by non-existing file ids
  doAssertRaises(CfApiError):
    discard await fetchAddonFiles(@[2992184, 99999999])

asyncBlock: # fetch mod file by project & file id
  let modFile = await fetchAddonFile(306770, 2992184)
  doAssert modFile.fileId == 2992184
  doAssert modFile.name == "Patchouli-1.0-21.jar"

asyncBlock: # fetch mod files by non-existing project & file id
  doAssertRaises(CfApiError):
    discard await fetchAddonFile(306770, 99999999)
  doAssertRaises(CfApiError):
    discard await fetchAddonFile(99999999, 2992184)

asyncBlock: # check if dependencies are tracked
  let modFile = await fetchAddonFile(243121, 3366626)
  doAssert modFile.dependencies == @[250363]

runTests()