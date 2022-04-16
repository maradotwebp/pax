import std/[algorithm, sequtils, strutils, sugar]
import ../api/cfcore
import ../modpack/manifest
import ../term/[log, prompt]

type
  PaxSearchError* = object of IOError

proc echoAddon*(
  mcMod: CfAddon,
  prefix: TermOut = "",
  postfix: TermOut = "",
  url: TermOut = mcMod.websiteUrl.dim,
  moreInfo: bool = false
): void =
  ## output a single `mcMod`.
  ## `prefix` and `postfix` is displayed before and after the mod name respectively.
  ## if `moreInfo` is true, description and downloads will be printed as well.
  var modname = mcMod.name
  var prefixIndent = 0
  if prefix.strLen != 0:
    modname = " " & modname
    prefixIndent = prefix.strLen + 1
  if postfix.strLen != 0:
    modname = modname & " "

  echoClr indentPrefix, prefix, modname, postfix, " - ", url
  if moreInfo:
    echoClr indentPrefix.indent(3 + prefixIndent), "Description: ".fgCyan, mcMod.description
    echoClr indentPrefix.indent(3 + prefixIndent), "Downloads: ".fgCyan, mcMod.downloads.`$`.insertSep('.')

proc promptAddonChoice*(manifest: Manifest, mcMods: seq[CfAddon], selectInstalled: bool = false): CfAddon =
  ## prompt the user for a choice between `mcMods`.
  ## if `selectInstalled` is true, only installed mods may be selected, otherwise installed mods may not be selected.
  var mcMods = mcMods.reversed
  if selectInstalled:
    mcMods.keepIf((x) => manifest.isInstalled(x.projectId))
    if manifest.files.len == 0:
      raise newException(PaxSearchError, "No installed mods detected.")
  if mcMods.len == 0:
    raise newException(PaxSearchError, "No mods found.")
  if mcMods.len == 1:
    return mcMods[0]

  var availableIndexes = newSeq[int]()
  
  echoRoot "RESULTS".dim
  for index, mcMod in mcMods:
    let isInstalled = manifest.isInstalled(mcMod.projectId)
    let isSelectable = selectInstalled == isInstalled
    let selectIndex = mcMods.len - index
    if isSelectable:
      availableIndexes.add(selectIndex)

    let prefix: string =
      if isSelectable: ("[" & $selectIndex & "]").align(4)
      else: "    "
    let postfix: string =
      if isInstalled: "[installed]"
      else: ""

    echoAddon(mcMod, prefix.fgCyan, postfix.fgMagenta)

  let selectedIndex = prompt("Select a mod", choices = availableIndexes.map((x) => $x), choiceFormat = "1 - " & $mcMods.len).parseInt
  return mcMods[mcMods.len - selectedIndex]