import asyncdispatch, httpclient

const
  forgeVersionUrl* = "http://raw.githubusercontent.com/MultiMC/meta-upstream/master/forge/derived_index.json"
  modsBaseUrl* = "https://addons-ecs.forgesvc.net/api/v2/"

proc getModUrl*(projectId: int): string =
  ## return the mod url for a given project id
  result = modsBaseUrl & "addon/" & $projectId

proc getModFileUrl*(projectId: int, fileId: int): string =
  ## return the mod file url for a given project & file id
  result = getModUrl(projectId) & "/file/" & $fileId

proc getModFilesUrl*(projectId: int): string =
  ## return the mod files url for a given project id
  result = getModUrl(projectId) & "/files"

proc fetch*(url: string): string =
  ## fetch the content of a given url
  let http = newHttpClient()
  result = http.getContent(url)

proc asyncFetch*(url: string): Future[string] {.async.} =
  ## fetch the content of a given url asynchronously
  let http = newAsyncHttpClient()
  result = await http.getContent(url)