import algorithm, sequtils, strutils, sugar, terminal, options
import ../api/cf
import ../cli/clr, ../cli/prompt, ../cli/term
import ../modpack/files

export terminal, term, files, strutils

proc echoMod*(cfMod: CfMod, prefix: TermOut = "", postfix: TermOut = "", url: TermOut = cfMod.websiteUrl.dim, moreInfo: bool = false): void =
  ## output a single `cfMod`.
  ## `prefix` and `postfix` is displayed before and after the mod name respectively.
  ## if `moreInfo` is true, description and downloads will be printed as well.
  var modname = cfMod.name
  var prefixIndent = 0
  if prefix.strLen != 0:
    modname = " " & modname
    prefixIndent = prefix.strLen + 1
  if postfix.strLen != 0:
    modname = modname & " "

  echoClr indentPrefix, prefix, modname, postfix, " - ", url
  if moreInfo:
    echoClr indentPrefix.indent(3 + prefixIndent), "Description: ".cyanFg, cfMod.description
    echoClr indentPrefix.indent(3 + prefixIndent), "Downloads: ".cyanFg, cfMod.downloads.`$`.insertSep('.')

proc promptModChoice*(manifest: Manifest, cfMods: seq[CfMod], selectInstalled: bool = false): Option[CfMod] =
  ## prompt the user for a choice between `cfMods`.
  ## if `selectInstalled` is true, only installed mods may be selected, otherwise installed mods may not be selected.
  var cfMods = cfMods.reversed
  if selectInstalled:
    cfMods.keepIf((x) => manifest.isInstalled(x.projectId))
    if manifest.files.len == 0:
      return none[CfMod]()
  if cfMods.len == 0:
    return none[CfMod]()
  if cfMods.len == 1:
    return some(cfMods[0])

  var availableIndexes = newSeq[int]()
  
  echoRoot "RESULTS".dim
  for index, cfMod in cfMods:
    let isInstalled = manifest.isInstalled(cfMod.projectId)
    let isSelectable = selectInstalled == isInstalled
    let selectIndex = cfMods.len - index
    if isSelectable:
      availableIndexes.add(selectIndex)

    let prefix: string =
      if isSelectable: ("[" & $selectIndex & "]").align(4)
      else: "    "
    let postfix: string =
      if isInstalled: "[installed]"
      else: ""

    echoMod(cfMod, prefix.cyanFg, postfix.magentaFg)

  let selectedIndex = prompt("Select a mod", choices = availableIndexes.map((x) => $x), choiceFormat = "1 - " & $cfMods.len).parseInt
  return some(cfMods[cfMods.len - selectedIndex])