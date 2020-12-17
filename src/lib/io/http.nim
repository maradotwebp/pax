import asyncdispatch, httpclient, uri

const
  forgeVersionUrl* = "http://raw.githubusercontent.com/MultiMC/meta-upstream/master/forge/derived_index.json"
  modsBaseUrl* = "https://addons-ecs.forgesvc.net/api/v2/"

template searchUrl*(s: string): string = modsBaseUrl & "addon/search?gameId=432&sectionId=6&pageSize=50&searchFilter=" & encodeUrl(s, usePlus=false)
template modUrl*(projectId: int): string = modsBaseUrl & "addon/" & $projectId
template modFileUrl*(projectId: int, fileId: int): string = modUrl(projectId) & "/file/" & $fileId
template modFilesUrl*(projectId: int): string = modUrl(projectId) & "/files"

proc fetch*(url: string): string =
  ## fetch the content of a given url
  let http = newHttpClient()
  result = http.getContent(url)

proc asyncFetch*(url: string): Future[string] {.async.} =
  ## fetch the content of a given url asynchronously
  let http = newAsyncHttpClient()
  result = await http.getContent(url)