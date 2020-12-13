import cligen, strformat
import cmd/db, cmd/init
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
  dispatchMulti(
    ["multi", noHdr=true, doc=multiDoc, usage=multiUsage],
    [cmdInit, noHdr=true, cmdName="init", usage=cmdUsage, help={
      "force": "will override files if necessary"
    }],
    [cmdUpdateDb, noHdr=true, cmdName="update-db", usage=cmdUsage]
  )