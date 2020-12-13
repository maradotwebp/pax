import httpclient

const
  forgeVersionUrl* = "http://raw.githubusercontent.com/MultiMC/meta-upstream/master/forge/derived_index.json"

proc fetch*(url: string): string =
  ## fetch the content of a given url
  let http = newHttpClient()
  result = http.getContent(url)