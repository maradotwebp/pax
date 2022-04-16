## Provides `getModLoaderId` which retrieves the modloader id (a string specifying
## the type & version of the modloader) given a minecraft version and type of modloader.
## 
## Pax currently has support for the Forge & Fabric modloader. The information about
## what loader version corresponds to what minecraft version is retrieved online
## and should be generally up-to-date 99% of the time.

import std/[asyncdispatch, json, strutils]
import http
import ../modpack/version, ../modpack/loader

const
  ## base url of the fabric metadata endpoint
  fabricBaseUrl = "https://meta.fabricmc.net/v2/versions/loader/"
  ## base url of the curse metadata api endpoint
  forgeBaseUrl = "https://cfproxy.fly.dev/v1/minecraft/modloader"

type
  MetadataClientError* = object of HttpRequestError

proc getFabricLoaderVersion(mcVersion: Version): Future[string] {.async.} =
  ## get the fabric loader version fitting for the given minecraft version
  let url = fabricBaseUrl & $mcVersion
  let json: JsonNode = try:
    get(url.Url).await.parseJson
  except HttpRequestError:
    raise newException(MetadataClientError, "'" & $mcVersion & "' is not a valid mc version.")
  let loaderElems = json.getElems()
  if loaderElems.len == 0:
    raise newException(MetadataClientError, "'" & $mcVersion & "' is not a valid mc version.")
  let ver = loaderElems[0]["loader"]["version"].getStr()
  return ver

proc getForgeLoaderVersion(mcVersion: Version, latest: bool): Future[string] {.async.} =
  ## get the forge loader version fitting for the given minecraft version
  let url = forgeBaseUrl & "?version=" & $mcVersion
  let json: JsonNode = try:
    get(url.Url).await.parseJson
  except HttpRequestError:
    raise newException(MetadataClientError, "'" & $mcVersion & "' is not a valid mc version.")
  let searchKey = if latest: "latest" else: "recommended"
  for item in json["data"].items():
    if item[searchKey].getBool():
      return item["name"].getStr()
  raise newException(MetadataClientError, "'" & $mcVersion & "' is not a valid mc version.")

proc toModloaderId(loaderVersion: string, loader: Loader): string =
  ## get the modloader id fitting for the given loader version and loader
  return case loader:
    of Loader.Forge: "forge-" & loaderVersion.split("-")[1]
    of Loader.Fabric: "fabric-" & loaderVersion

proc getModloaderId*(mcVersion: Version, loader: Loader, latest: bool = false): Future[string] {.async.} =
  ## get the modloader id fitting for the given minecraft version and loader
  let loaderVersion = case loader:
    of Loader.Forge: await mcVersion.getForgeLoaderVersion(latest)
    of Loader.Fabric: mcVersion.getFabricLoaderVersion().await.toModloaderId(loader)
  return loaderVersion