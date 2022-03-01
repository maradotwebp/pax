import therapist
import cmd/add, cmd/expo, cmd/impo, cmd/init, cmd/list, cmd/pin, cmd/remove, cmd/update, cmd/upgrade, cmd/version
import term/color, term/prompt
import util/paxVersion

let commonArgs = (
  strategy: newStringArg(@["-s", "--strategy"],
    choices = @["stable", "recommended", "newest"],
    defaultVal = "recommended",
    help = "how pax determines the version to install"
  ),
  yes: newCountArg(@["-y"],
    help = "accept all interactive prompts"
  ),
  noColor: newCountArg(@["--no-color"],
    help = "disable colored output"
  ),
  # Version should only work with no subcommands
  version: newMessageArg(@["-v", "--version"],
    currentPaxVersion,
    help = "show version information"
  ),
  help: newHelpArg(@["-h", "--help"],
    help = "show help message"
  )
)

let initCmd = (
  force: newCountArg(@["-f", "--force"],
    help = "will override an existing project in this folder"
  ),
  skipManifest: newCountArg(@["--skip-manifest"],
    help = "skip creating the modpack folder"
  ),
  skipGit: newCountArg(@["--skip-git"],
    help = "skip creating a git repository"
  ),
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let listCmd = (
  status: newCountArg(@["-s", "--status"],
    help = "display mod compability and freshness"
  ),
  info: newCountArg(@["-i", "--info"],
    help = "display more mod information"
  ),
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let addCmd = (
  input: newStringArg(@["<input>"],
    multi = true,
    help = "modname, projectid or curseforge url of the mod to add"
  ),
  noDepends: newCountArg(@["--no-deps"],
    help = "don't install dependencies"
  ),
  addonType: newStringArg(@["-t", "--type"],
    choices = @["mod", "resourcepack"],
    help = "restrict search to a certain addon type"
  ),
  strategy: commonArgs.strategy,
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let removeCmd = (
  name: newStringArg(@["<name>"],
    multi = true,
    help = "name of the mod to remove"
  ),
  strategy: commonArgs.strategy,
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let pinCmd = (
  name: newStringArg(@["<name>"],
    multi = true,
    help = "name of the mod to pin"
  ),
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let updateCmd = (
  name: newStringArg(@["<name>"],
    multi = true,
    help = "name of the mod to update"
  ),
  strategy: commonArgs.strategy,
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let upgradeCmd = (
  strategy: commonArgs.strategy,
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let versionCmd = (
  version: newStringArg(@["<version>"],
    help = "Minecraft version"
  ),
  loader: newStringArg(@["-l", "--loader"],
    choices = @["fabric", "forge"],
    help = "which loader to use"
  ),
  latest: newCountArg(@["--latest"],
    help = "install the latest loader version instead of the recommended one"
  ),
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let importCmd = (
  path: newFileArg(@["<path>"],
    help = "path to file"
  ),
  force: newCountArg(@["-f", "--force"],
    help = "will override the modpack folder if it already exists"
  ),
  skipGit: newCountArg(@["--skip-git"],
    help = "skip creating a git repository"
  ),
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let exportCmd = (
  path: newStringArg(@["<path>"],
    help = "path to output file",
    optional = true,
    helpvar = "./.out/<modpackname>.zip"
  ),
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  help: commonArgs.help
)

let spec = (
  init: newCommandArg(@["init"],
    initCmd,
    help = "initialize a new pax project"
  ),
  list: newCommandArg(@["ls", "list"],
    listCmd,
    help = "list installed mods"
  ),
  add: newCommandArg(@["add"],
    addCmd,
    help = "add a new mod to the modpack"
  ),
  remove: newCommandArg(@["remove"],
    removeCmd,
    help = "remove a mod from the modpack"
  ),
  pin: newCommandArg(@["pin"],
    pinCmd,
    help = "pin/unpin a mod to its current version"
  ),
  update: newCommandArg(@["update"],
    updateCmd,
    help = "update a specific mod"
  ),
  upgrade: newCommandArg(@["upgrade"],
    upgradeCmd,
    help = "upgrade ALL mods"
  ),
  version: newCommandArg(@["version"],
    versionCmd,
    help = "set minecraft & loader version"
  ),
  impo: newCommandArg(@["import"],
    importCmd,
    help = "import from .zip"
  ),
  expo: newCommandArg(@["export"],
    exportCmd,
    help = "export to .zip"
  ),
  yes: commonArgs.yes,
  noColor: commonArgs.noColor,
  paxVersion: commonArgs.version,
  help: commonArgs.help
)

spec.parseOrHelp()

# GLOBAL OPTIONS
if commonArgs.yes.seen:
  skipYNSetting = true
if commonArgs.noColor.seen:
  terminalColorEnabledSetting = false

# COMMANDS
if spec.init.seen:
  paxInit(force = initCmd.force.seen, skipManifest = initCmd.skipManifest.seen,
      skipGit = initCmd.skipGit.seen)
elif spec.list.seen:
  paxList(status = listCmd.status.seen, info = listCmd.info.seen)
elif spec.add.seen:
  paxAdd(
    input = addCmd.input.value,
    noDepends = addCmd.noDepends.seen,
    strategy = addCmd.strategy.value,
    addonType = addCmd.addonType.value
  )
elif spec.remove.seen:
  paxRemove(name = removeCmd.name.value, strategy = removeCmd.strategy.value)
elif spec.pin.seen:
  paxPin(name = pinCmd.name.value)
elif spec.update.seen:
  paxUpdate(name = updateCmd.name.value, strategy = updateCmd.strategy.value)
elif spec.upgrade.seen:
  paxUpgrade(strategy = upgradeCmd.strategy.value)
elif spec.version.seen:
  if versionCmd.loader.seen:
    paxVersion(version = versionCmd.version.value, loader = versionCmd.loader.value, latest = versionCmd.latest.seen)
  else:
    paxVersion(version = versionCmd.version.value, latest = versionCmd.latest.seen)
elif spec.impo.seen:
  paxImport(path = importCmd.path.value, force = importCmd.force.seen,
      skipGit = importCmd.skipGit.seen)
elif spec.expo.seen:
  paxExport(path = exportCmd.path.value)
else:
  echo spec.render_help()
