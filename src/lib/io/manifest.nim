import json
import ../cmd/cmd

proc createManifest*(project: Project): string =
    ## creates the json for a manifest from a project
    let json = %* {
            "minecraft": {
                "version": project.mcVersion,
                "modLoaders": [{ "id": project.mcModloaderId, "primary": true }]
            },
            "manifestType": "minecraftModpack",
            "overrides": "overrides",
            "manifestVersion": 1,
            "version": project.version,
            "author": project.author,
            "name": project.name,
            "files": []
        }
    result = pretty(json)