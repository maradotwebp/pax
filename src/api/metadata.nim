## Provides `getModLoaderId` which retrieves the modloader id (a string specifying
## the type & version of the modloader) given a minecraft version and modloader.
## 
## Pax currently has support for the Forge & Fabric modloader. The information about
## what loader version corresponds to what minecraft version is retrieved online
## and should be generally up-to-date 99% of the time.

import asyncdispatch, json, options, strutils, sugar
import http
import ../modpack/version, ../modpack/loader

const
  ## base url of the fabric metadata endpoint
  fabricBaseUrl = "https://meta.fabricmc.net/v2/versions/loader/"
  ## base url of the curse metadata api endpoint
  forgeBaseUrl = "http://raw.githubusercontent.com/MultiMC/meta-upstream/master/forge/derived_index.json"

proc getFabricLoaderVersion(mcVersion: Version): Future[Option[string]] {.async.} =
  ## get the fabric loader version fitting for the given minecraft version
  let url = fabricBaseUrl & $mcVersion
  var json: JsonNode
  try:
    json = get(url.Url).await.parseJson
  except HttpRequestError:
    return none[string]()
  let loaderElems = json.getElems()
  if loaderElems.len == 0:
    return none[string]()
  let ver = loaderElems[0]["loader"]["version"].getStr()
  return some(ver)

proc getForgeLoaderVersion(mcVersion: Version, latest: bool): Future[Option[string]] {.async.} =
  ## get the forge loader version fitting for the given minecraft version
  let json = get(forgeBaseUrl.Url).await.parseJson
  let recommendedVersion = json{"by_mcversion", $mcVersion, "recommended"}.getStr()
  let latestVersion = json{"by_mcversion", $mcVersion, "latest"}.getStr()
  let forgeVersion = if latest:
    latestVersion
  else:
    if $recommendedVersion != "": recommendedVersion else: latestVersion
  return if forgeVersion != "": some(forgeVersion) else: none[string]()

proc toModloaderId(loaderVersion: string, loader: Loader): string =
  ## get the modloader id fitting for the given loader version and loader
  return case loader:
    of Loader.Forge: "forge-" & loaderVersion.split("-")[1]
    of Loader.Fabric: "fabric-" & loaderVersion

proc getModloaderId*(mcVersion: Version, loader: Loader, latest: bool = false): Future[Option[string]] {.async.} =
  ## get the modloader id fitting for the given minecraft version and loader
  let loaderVersion = case loader:
    of Loader.Forge: await mcVersion.getForgeLoaderVersion(latest)
    of Loader.Fabric: await mcVersion.getFabricLoaderVersion()
  return loaderVersion.map((x) => toModloaderId(x, loader))