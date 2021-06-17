import therapist
import cmd/add, cmd/expo, cmd/impo, cmd/init, cmd/list, cmd/remove, cmd/update, cmd/upgrade, cmd/version

let strategyArg = newStringArg(@["-s", "--strategy"], choices = @["recommended", "newest"], defaultVal = "recommended", help = "how pax determines the version to install")

let initCmd = (
  force: newCountArg(@["-f", "--force"], help = "will override manifest.json if it already exists"),
  help: newHelpArg()
)

let listCmd = (
  status: newCountArg(@["-s", "--status"], help = "display mod compability and freshness"),
  info: newCountArg(@["-i", "--info"], help = "display more mod information"),
  help: newHelpArg()
) 

let addCmd = (
  input: newStringArg(@["<input>"], multi = true, help = "modname, projectid or curseforge url of the mod to add"),
  strategy: strategyArg,
  help: newHelpArg()
)

let removeCmd = (
  name: newStringArg(@["<name>"], help = "name of the mod to remove"),
  help: newHelpArg()
)

let updateCmd = (
  name: newStringArg(@["<name>"], help = "name of the mod to update"),
  strategy: strategyArg,
  help: newHelpArg()
)

let upgradeCmd = (
  strategy: strategyArg,
  help: newHelpArg()
)

let versionCmd = (
  version: newStringArg(@["<version>"], help = "Minecraft version"),
  loader: newStringArg(@["-l", "--loader"], choices = @["fabric", "forge"], help = "which loader to use"),
  help: newHelpArg()
)

let importCmd = (
  path: newFileArg(@["<path>"], help = "path to file"),
  force: newCountArg(@["-f", "--force"], help = "will override the modpack folder if it already exists"),
  help: newHelpArg()
)

let exportCmd = (
  help: newHelpArg()
)

let spec = (
  init: newCommandArg(@["init"], initCmd, help = "initialize a new pax project"),
  list: newCommandArg(@["ls", "list"], listCmd, help = "list installed mods"),
  add: newCommandArg(@["add"], addCmd, help = "add a new mod to the modpack"),
  remove: newCommandArg(@["remove"], removeCmd, help = "remove a mod from the modpack"),
  update: newCommandArg(@["update"], updateCmd, help = "update a specific mod"),
  upgrade: newCommandArg(@["upgrade"], upgradeCmd, help = "upgrade ALL mods"),
  version: newCommandArg(@["version"], versionCmd, help = "set minecraft & loader version"),
  impo: newCommandArg(@["import"], importCmd, help = "import from .zip"),
  expo: newCommandArg(@["export"], exportCmd, help = "export to .zip"),
  help: newHelpArg()
)

spec.parseOrHelp()

if spec.init.seen:
  paxInit(force = initCmd.force.seen)
elif spec.list.seen:
  paxList(status = listCmd.status.seen, info = listCmd.info.seen)
elif spec.add.seen:
  paxAdd(input = addCmd.input.value, strategy = addCmd.strategy.value)
elif spec.remove.seen:
  paxRemove(name = removeCmd.name.value)
elif spec.update.seen:
  paxUpdate(name = updateCmd.name.value, strategy = updateCmd.strategy.value)
elif spec.upgrade.seen:
  paxUpgrade(strategy = upgradeCmd.strategy.value)
elif spec.version.seen:
  if versionCmd.loader.seen:
    paxVersion(version = versionCmd.version.value, loader = versionCmd.loader.value)
  else:
    paxVersion(version = versionCmd.version.value)
elif spec.impo.seen:
  paxImport(path = importCmd.path.value, force = importCmd.force.seen)
elif spec.expo.seen:
  paxExport()
else:
  echo spec.render_help()