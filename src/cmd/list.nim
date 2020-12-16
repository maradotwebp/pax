import asyncdispatch, asyncfutures, sequtils, json
import ../lib/io/files, ../lib/io/http, ../lib/io/io, ../lib/io/term
import ../lib/obj/manifest, ../lib/obj/mods, ../lib/obj/modutils

proc cmdList*(): void =
    ## list installed mods & their current versions
    requirePaxProject

    echoDebug "Loading files from manifest.."
    let manifestJson = parseJson(readFile(manifestFile))
    let project = projectFromJson(manifestJson)
    let fileCount = project.files.len
    let allModRequests = project.files.map(proc(file: ManifestFile): Future[tuple[mcMod: McMod, mcModFile: McModFile]] {.async.} =
        let modContent = await asyncFetch(modUrl(file.projectId))
        let modFileContent = await asyncFetch(modFileUrl(file.projectId, file.fileId))
        let mcMod = modFromJson(parseJson(modContent))
        let mcModFile = modFileFromJson(parseJson(modFileContent))
        return (mcMod, mcModFile)
    )

    echoInfo "Loading mods.."
    let contents = waitFor(all(allModRequests))
    echoRoot " ALL MODS ".clrMagenta, ("(" & $fileCount & ")").clrGray
    for index, content in contents:
        let mcMod = content.mcMod
        let mcModFile = content.mcModFile
        let fileUrl = mcMod.websiteUrl & "/files/" & $mcModFile.fileId
        let fileCompabilityIcon: string = case mcModFile.getFileCompability(project.mcVersion)
            of Compability.full: "•".clrGreen
            of Compability.major: "•".clrYellow
            of Compability.none: "•".clrRed
        let fileFreshnessIcon: string = case mcModFile.getFileFreshness(project.mcVersion, mcMod)
            of Freshness.newest: "↑".clrGreen
            of Freshness.newestForAVersion: "↑".clrYellow
            of Freshness.old: "↑".clrRed
        echo promptPrefix, fileCompabilityIcon, fileFreshnessIcon, " ", mcMod.name, " ", fileUrl.clrGray