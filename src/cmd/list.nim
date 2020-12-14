import asyncdispatch, asyncfutures, sequtils, json
import ../lib/io/files, ../lib/io/http, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/mods, ../lib/obj/modutils

proc cmdList*(): void =
    ## list installed mods & their current versions
    requirePaxProject

    echoDebug "Loading files from manifest.."
    let manifestJson = parseJson(readFile(manifestFile))
    let project = projectFromJson(manifestJson)
    let fileCount = project.files.len
    let allModRequests = project.files.map(proc(file: ManifestFile): Future[tuple[mcMod: McMod, mcModFile: McModFile]] {.async.} =
        let modContent = await asyncFetch(getModUrl(file.projectId))
        let modFileContent = await asyncFetch(getModFileUrl(file.projectId, file.fileId))
        let mcMod = modFromJson(parseJson(modContent), file.fileId)
        let mcModFile = modFileFromJson(parseJson(modFileContent))
        return (mcMod, mcModFile)
    )
    echoInfo "Loading mods.."
    let contents = waitFor(all(allModRequests))
    echo "[" & "Δ".clrMagenta & "]", " ", "ALL MODS ".clrMagenta, ("(" & $fileCount & ")").clrGray
    for index, content in contents:
        let mcMod = content.mcMod
        let mcModFile = content.mcModFile
        let fileCompabilityIcon: string = case mcModFile.getFileCompability(project.mcVersion)
            of Compability.full: "•".clrGreen
            of Compability.major: "•".clrYellow
            of Compability.none: "•".clrRed
        let fileFreshnessIcon: string = case mcModFile.getFileFreshness(project.mcVersion, mcMod)
            of Freshness.newest: "↑".clrGreen
            of Freshness.newestForAVersion: "↑".clrYellow
            of Freshness.old: "↑".clrRed
        echo " └─ ", fileCompabilityIcon, fileFreshnessIcon, " ", mcMod.name