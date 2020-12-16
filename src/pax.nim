import cligen, strformat
import cmd/expo, cmd/init, cmd/list, cmd/mods
import lib/io/term

const
  ## Doc string for the main command.
  multiDoc = "A modpack development manager for minecraft."

  ## Usage string for the main command.
  multiUsage = fmt"""
:: $doc
{"USAGE".clrYellow}:
  $command <SUBCOMMAND>
{"SUBCOMMANDS".clrYellow}:
$subCmds"""

  ## Usage string for a subcommand.
  cmdUsage = fmt"""$doc{"USAGE".clrYellow}:
  pax $command $args
{"OPTIONS".clrYellow}:
$options"""

when isMainModule:
  setControlCHook(proc() {.noconv.}= quit(1))
  dispatchMulti(
    ["multi", noHdr=true, doc=multiDoc, usage=multiUsage],
    [cmdInit, noHdr=true, cmdName="init", usage=cmdUsage, help={
      "force": "will override the manifest.json if it already exists"
    }],
    [cmdMod, noHdr=true, cmdName="mod", usage=cmdUsage],
    [cmdList, noHdr=true, cmdName="ls", usage=cmdUsage],
    [cmdExport, noHdr=true, cmdName="export", usage=cmdUsage]
  )