import httpclient

const
  forgeVersionUrl = "http://raw.githubusercontent.com/MultiMC/meta-upstream/master/forge/derived_index.json"

proc downloadForgeVersions*: string =
  ## download the MultiMC file declaring which forge version to choose for which minecraft version
  var http = newHttpClient()
  result = http.getContent(forgeVersionUrl)