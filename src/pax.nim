import cligen, strformat
import lib/cmd/flow, lib/cmd/init
import lib/io/files, lib/io/term

const
  ## Doc string for the main command.
  multiDoc = "A modpack development manager for minecraft."

  ## Usage string for the main command.
  multiUsage = fmt"""
:: $doc
{"USAGE".yellow}:
  $command <SUBCOMMAND>
{"SUBCOMMANDS".yellow}:
$subCmds"""

  ## Usage string for a subcommand.
  cmdUsage = fmt"""$doc{"USAGE".yellow}:
  $command $args
{"OPTIONS".yellow}:
$options"""

proc init(force = false): void =
  ## initialize a new modpack in the current directory
  if not force:
    rejectPaxProject
  returnIfNot readYesNo("Are you sure you want to create a pax project in the current folder?", default='y')
  createCacheFolder()
  let project = initProject()
  createPackFolder(project)

when isMainModule:
  dispatchMulti(
    ["multi", doc=multiDoc, usage=multiUsage],
    [init, usage=cmdUsage, help={
      "force": "will override files if necessary"
    }]
  )