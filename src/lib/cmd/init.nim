import cmd
import ../io/files, ../io/term

proc initProject*(): Project =
  ## create a project from user inputs
  result.name = readInput("Modpack name")
  result.author = readInput("Modpack author")
  result.version = readInput("Modpack version", default="1.0.0")
  result.mcVersion = readInput("Minecraft version", default="1.16.4")
  let forgeVersion = getForgeVersion(result.mcVersion)
  if forgeVersion == "":
    echoError "This is either not a minecraft version, or no forge version exists for this minecraft version."
    return
  result.mcModloaderId = forgeVersion