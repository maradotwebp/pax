import asyncdispatch, httpclient

proc fetch*(url: string): Future[string] {.async.} =
  ## fetch the content of a given `url` asynchronously
  let http = newAsyncHttpClient()
  result = await http.getContent(url)

proc post*(url: string, body: string): Future[string] {.async.} =
  ## fetch the content of a given `url` with a POST request (asynchronously)
  let http = newAsyncHttpClient()
  http.headers = newHttpHeaders({ "Content-Type": "application/json" })
  result = await http.postContent(url, body)