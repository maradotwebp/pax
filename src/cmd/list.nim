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
    let allModRequests = project.files.map(proc(file: ManifestFile): Future[McMod] {.async.} =
        return (await asyncFetch(modUrl(file.projectId))).parseJson.modFromJson
    )
    let allModFileRequests = project.files.map(proc(file: ManifestFile): Future[McModFile] {.async.} =
        return (await asyncFetch(modFileUrl(file.projectId, file.fileId))).parseJson.modFileFromJson
    )
    let mods = all(allModRequests)
    let modFiles = all(allModFileRequests)

    echoInfo "Loading mods.."
    waitFor(mods and modFiles)
    echoRoot " ALL MODS ".clrMagenta, ("(" & $fileCount & ")").clrGray
    for index, content in zip(mods.read(), modFiles.read()):
        let mcMod = content[0]
        let mcModFile = content[1]
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