import sequtils, strutils, sugar, terminal, options
import ../api/cf
import ../cli/prompt, ../cli/term
import ../modpack/files

export terminal, term, files, strutils

proc echoMod*(cfMod: CfMod, prefix: string = "", postfix: string = "", moreInfo: bool = false): void =
  ## output a single `cfMod`.
  ## `prefix` and `postfix` is displayed before and after the mod name respectively.
  ## if `moreInfo` is true, description and downloads will be printed as well.
  var modname = cfMod.name
  if prefix != "":
    modname = " " & modname
  if postfix != "":
    modname = modname & " "

  styledEcho indentPrefix, prefix, modname, postfix, " - ", styleDim, cfMod.websiteUrl
  if moreInfo:
    styledEcho indentPrefix.indent(3), fgCyan, "Description: ", resetStyle, cfMod.description
    styledEcho indentPrefix.indent(3), fgCyan, "Downloads: ", resetStyle, cfMod.downloads.`$`.insertSep('.')

proc promptModChoice*(manifest: Manifest, cfMods: seq[CfMod], selectInstalled: bool = false): Option[CfMod] =
  ## prompt the user for a choice between `cfMods`.
  ## if `selectInstalled` is true, only installed mods may be selected, otherwise installed mods may not be selected.
  var cfMods = cfMods
  if selectInstalled:
    cfMods.keepIf((x) => manifest.isInstalled(x.projectId))
    if manifest.files.len == 0:
      return none[CfMod]()
  if cfMods.len == 0:
    return none[CfMod]()
  if cfMods.len == 1:
    return some(cfMods[0])
  
  echoRoot styleDim, "RESULTS"
  for index, cfMod in cfMods:
    let isInstalled = manifest.isInstalled(cfMod.projectId)
    let isSelectable = selectInstalled == isInstalled
    let prefix: string =
      if isSelectable: ("[" & $(index+1) & "]").align(4)
      else: "    "
    let postfix: string =
      if isInstalled: "[installed]"
      else: ""

    echoMod(cfMod, prefix, postfix)

  var availableIndexes = toSeq(1..cfMods.len)
  if selectInstalled:
    availableIndexes.keepIf((x) => manifest.isInstalled(cfMods[x - 1].projectId))
  if not selectInstalled:
    availableIndexes.keepIf((x) => not manifest.isInstalled(cfMods[x - 1].projectId))

  let selectedIndex = prompt("Select a mod", choices = availableIndexes.map((x) => $x), choiceFormat = "1 - " & $cfMods.len).parseInt
  return some(cfMods[selectedIndex - 1])