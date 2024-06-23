import std/[asyncdispatch, os, osproc]
import ../api/[cfclient, cfcore, metadata]
import ../modpack/[manifest, install, loader, version]
import ../term/[log, prompt]
import ../util/flow

proc paxInitManifest(): void =
  ## initialize the modpack files (modpack folder structure & `manifest.json`)
  echoRoot "MANIFEST".dim
  var manifest = Manifest()
  manifest.name = prompt(indentPrefix & "Modpack name")
  manifest.author = prompt(indentPrefix & "Modpack author")
  manifest.version = prompt(indentPrefix & "Modpack version", default = "1.0.0")
  manifest.mcVersion = Version(prompt(indentPrefix & "Minecraft version", default = "1.16.5"))

  let loader = prompt(indentPrefix & "Loader", choices = @["forge", "fabric", "quilt"], default = "forge").toLoader
  manifest.mcModloaderId = waitFor(manifest.mcVersion.getModloaderId(loader))
  echoDebug "Installed ", $loader, " version ", manifest.mcModloaderId.fgGreen
  if loader == Loader.Quilt:
    let mcJumploaderMod = waitFor(fetchAddon(640265))
    let mcJumploaderModFiles = waitFor(fetchAddonFiles(mcJumploaderMod.projectId))
    let mcJumploaderModFile = mcJumploaderModFiles.selectAddonFile(loader, manifest.mcVersion, InstallStrategy.Recommended)
    let jumploaderMod = initManifestFile(
      projectId = mcJumploaderMod.projectId,
      fileId = mcJumploaderModFile.fileId,
      metadata = initManifestMetadata(
        name = mcJumploaderMod.name,
        explicit = true,
        pinned = true,
        dependencies = mcJumploaderModFile.dependencies
      )
    )
    manifest.installAddon(jumploaderMod)
    echoDebug "Installed Jumploader."
    echoWarn "Quilt support is experimental. Report all issues to https://github.com/maradotwebp/pax/issues."

  echoInfo "Creating manifest.."
  removeDir(packFolder)
  createDir(packFolder)
  createDir(overridesFolder)
  writeFile(paxFile, "Modpack generated by PAX")
  manifest.writeToDisk()

template exec(cmd: string): int = execCmdEx(cmd, options = {poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon}).exitCode

proc paxInitGit*(): void =
  ## initialize a git repository (+ gitignore and ci files)
  const successValue = 0
  const noGitRepositoryValue = 128

  try:
    if exec("git --version") == successValue:
      if exec("git status") == noGitRepositoryValue:
        echoDebug "Initializing .git repository.."
        discard exec("git init")
        discard exec("git branch -m main")

    echoDebug "Writing .gitignore.."
    writeFile(gitIgnoreFile, gitIgnoreContent)

    echoDebug "Writing Github CI file.."
    createDir(githubCiFolder)
    writeFile(githubCiFile, githubCiContent)
  except OSError:
    discard

proc paxInit*(force: bool, skipManifest: bool, skipGit: bool): void =
  ## initialize a new modpack in the current directory
  if not force:
    rejectPaxProject()
    returnIfNot promptYN("Are you sure you want to initialize the pax project in the current folder?", default = true)

  if not skipManifest:
    paxInitManifest()

  if not skipGit:
    paxInitGit()