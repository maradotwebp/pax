import cligen, sequtils, strformat, strutils, tables, json
import ../lib/io/cli, ../lib/io/files, ../lib/io/http, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/mods, ../lib/obj/modutils

proc cmdModUpdate(project: ManifestProject, mcMod: McMod): void =
    ## update a selected mod
    let installMethod = promptChoice("Install recommended or newest compatible version?", @['r', 'n'], format="[r]ecommended, [n]ewest", default='r')
    echoInfo "Updating ", mcMod.name.clrCyan, ".."
    let recommendedVersion = project.mcVersion
    let latestFiles = mcMod.gameVersionLatestFiles
    var newestCompatibleVersion = ""
    for k in latestFiles.keys:
        if getMajorVersion(project.mcVersion) == getMajorVersion(k):
            if newestCompatibleVersion != "":
                if k.laterVersionThan(newestCompatibleVersion):
                    newestCompatibleVersion = k
            else:
                newestCompatibleVersion = k

    let installVersion = if installMethod == 'r' and latestFiles.hasKey(recommendedVersion):
        recommendedVersion
    else:
        newestCompatibleVersion
    if installVersion == "":
        echoError "No compatible version of this mod was found."
        return

    var modProject = project
    let file = initManifestFile(projectId=mcMod.projectId, fileId=latestFiles[installVersion])
    keepIf(modProject.files, proc(f: ManifestFile): bool =
        f.projectId != mcMod.projectId
    )
    modProject.files = modProject.files & file

    echoDebug "Writing to manifest.."
    writeFile(manifestFile, modProject.toJson.pretty)

proc cmdModRemove(project: ManifestProject, mcMod: McMod): void =
    ## remove a selected mod
    echoInfo "Removing ", mcMod.name.clrCyan, ".."
    let projectId = mcMod.projectId
    var modProject = project
    keepIf(modProject.files, proc(f: ManifestFile): bool =
        f.projectId != projectId
    )

    echoDebug "Writing to manifest.."
    writeFile(manifestFile, modProject.toJson.pretty)

proc cmdModInstall(project: ManifestProject, mcMod: McMod): void =
    ## install a selected mod
    let installMethod = promptChoice("Install recommended or newest compatible version?", @['r', 'n'], format="[r]ecommended, [n]ewest", default='r')
    echoInfo "Installing ", mcMod.name.clrCyan, ".."
    let recommendedVersion = project.mcVersion
    let latestFiles = mcMod.gameVersionLatestFiles
    var newestCompatibleVersion = ""
    for k in latestFiles.keys:
        if getMajorVersion(project.mcVersion) == getMajorVersion(k):
            if newestCompatibleVersion != "":
                if k.laterVersionThan(newestCompatibleVersion):
                    newestCompatibleVersion = k
            else:
                newestCompatibleVersion = k

    let installVersion = if installMethod == 'r' and latestFiles.hasKey(recommendedVersion):
        recommendedVersion
    else:
        newestCompatibleVersion
    if installVersion == "":
        echoError "No compatible version of this mod was found."
        return

    var modProject = project
    let file = initManifestFile(projectId=mcMod.projectId, fileId=latestFiles[installVersion])
    modProject.files = modProject.files & file

    echoDebug "Writing to manifest.."
    writeFile(manifestFile, modProject.toJson.pretty)

proc cmdMod*(name: seq[string]): void =
    ## install, modify, update and get information about a mod
    requirePaxProject
    if name.len == 0:
        stderr.write "Missing these required parameters:\n"
        stderr.write "  name\n"
        raise newException(ParseError, "")

    echoDebug "Loading files from manifest.."
    let manifestJson = parseJson(readFile(manifestFile))
    let project = projectFromJson(manifestJson)
    var projectFileMap = initTable[int, int]()
    for file in project.files:
        projectFileMap[file.projectId] = file.fileId
    let isInstalled = proc(projectId: int): bool = projectId in projectFileMap
    let getInstallSuffix = proc(projectId: int): string =
        if isInstalled(projectId): " [installed]".clrMagenta else: ""

    echoDebug "Searching for name .."
    let modSearchJson = parseJson(fetch(searchUrl(name.join(" "))))
    let mcMods = modsFromJson(modSearchJson)
    echoRoot " RESULTS".clrGray
    for index, mcMod in mcMods:
        let installedSuffix = getInstallSuffix(mcMod.projectId)
        echo promptPrefix, ("[" & ($(index+1)).clrCyan & "]").align(13), " ", mcMod.name, installedSuffix, " ", mcMod.websiteUrl.clrGray

    let selectedIndex = promptChoice("Select a mod", toSeq(1..mcMods.len), "1 - " & $mcMods.len)
    
    let selectedMod = mcMods[selectedIndex - 1]
    let gameVersion = project.mcVersion
    let majorGameVersion = getMajorVersion(gameVersion)
    var selectedModFile: McModFile
    if isInstalled(selectedMod.projectId):
        let fileId = projectFileMap[selectedMod.projectId]
        let json = parseJson(fetch(modFileUrl(selectedMod.projectId, fileId)))
        selectedModFile = modFileFromJson(json)
    let installedSuffix = getInstallSuffix(selectedMod.projectId)
    let compability = selectedModFile.getFileCompability(project.mcVersion)
    let fileCompabilityMsg: string = case compability
        of Compability.full: "•".clrGreen & " " & "The installed mod is compatible with the modpack's minecraft version."
        of Compability.major: "•".clrYellow & " " & fmt"The installed mod has the same major version as the modpack ({majorGameVersion}). Issues may arise."
        of Compability.none: "•".clrRed & " " & "The installed mod is incompatible with the modpack's minecraft version."
    let freshness = selectedModFile.getFileFreshness(project.mcVersion, selectedMod)
    let fileFreshnessMsg: string = case freshness
        of Freshness.newest: "↑".clrGreen & " " & "No mod updates available."
        of Freshness.newestForAVersion: "↑".clrYellow & " " & "Your installed version is newer than the recommended version. Issues may arise."
        of Freshness.old: "↑".clrRed & " " & "There is a newer version of this mod available."
    
    echo ""
    echoRoot " SELECTED MOD".clrGray
    echo promptPrefix, selectedMod.name, installedSuffix, " ", selectedMod.websiteUrl.clrGray
    if isInstalled(selectedMod.projectId):
        echo promptPrefix.indent(3), fileCompabilityMsg
        echo promptPrefix.indent(3), fileFreshnessMsg
        echo "------------------------------".indent(4).clrGray
    echo promptPrefix.indent(3), "Description: ".clrCyan, selectedMod.description
    echo promptPrefix.indent(3), "Downloads: ".clrCyan, ($selectedMod.downloads).insertSep(sep='.')

    echo ""
    var actions = newSeq[char]()
    var format = ""
    if isInstalled(selectedMod.projectId):
        actions = @['u', 'r']
        format = "[u]pdate, [r]emove"
    else:
        actions = @['i']
        format = "[i]nstall"
    let selectedAction = promptChoice("Select an action", actions, format)
    case selectedAction:
        of 'u': cmdModUpdate(project, selectedMod)
        of 'r': cmdModRemove(project, selectedMod)
        of 'i': cmdModInstall(project, selectedMod)
        else: return