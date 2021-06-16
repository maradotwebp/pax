import asyncdispatch, httpclient

proc fetch*(url: string): Future[string] {.async.} =
  ## fetch the content of a given `url` asynchronously
  let http = newAsyncHttpClient()
  result = await http.getContent(url)