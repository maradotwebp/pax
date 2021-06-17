import asyncdispatch, json, options, strutils, sugar
import http
import ../mc/version
import ../modpack/loader

proc getFabricLoaderVersion(mcVersion: Version): Future[Option[string]] {.async.} =
  ## get the fabric loader version fitting for the given `mcVersion`
  let url = "https://meta.fabricmc.net/v2/versions/loader/" & $mcVersion
  let json = fetch(url).await.parseJson
  let loaderElems = json.getElems()
  if len(loaderElems) == 0:
      return none[string]()
  let ver = loaderElems[0]["loader"]["version"].getStr()
  return some(ver)

proc getForgeLoaderVersion(mcVersion: Version): Future[Option[string]] {.async.} =
  ## get the forge loader version fitting for the given `mcVersion`
  let url = "http://raw.githubusercontent.com/MultiMC/meta-upstream/master/forge/derived_index.json"
  let json = fetch(url).await.parseJson
  let recommendedVersion = json{"by_mcversion", $mcVersion, "recommended"}.getStr()
  let latestVersion = json{"by_mcversion", $mcVersion, "latest"}.getStr()
  let forgeVersion = if $recommendedVersion != "": recommendedVersion else: latestVersion
  return if forgeVersion != "": some(forgeVersion) else: none[string]()

proc toMcModloaderId(loaderVersion: string, loader: Loader): string =
  ## get the mcModloaderId (e.g. the `forge-1.15.3` in the manifest) fitting for the given `loaderVersion` and `loader`
  if loader == "forge":
    return "forge-" & loaderVersion.split("-")[1]
  else:
    return "fabric-" & loaderVersion

proc getMcModloaderId*(mcVersion: Version, loader: Loader): Future[Option[string]] {.async.} =
  ## get the mcModloaderId (e.g. the `forge-1.15.3` in the manifest) fitting for the given `mcVersion` and `loader`
  var loaderVersion: Option[string]
  if loader == Loader.fabric:
    loaderVersion = mcVersion.getFabricLoaderVersion.await
  else:
    loaderVersion = mcVersion.getForgeLoaderVersion.await
  return loaderVersion.map((x) => toMcModloaderId(x, loader))