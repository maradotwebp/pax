import asyncdispatch, httpclient, os

var proxy = ""
if existsEnv("http_proxy"):
  proxy = getEnv("http_proxy")
elif existsEnv("https_proxy"):
  proxy = getEnv("https_proxy")

proc fetch*(url: string): Future[string] {.async.} =
  ## fetch the content of a given `url` asynchronously
  let http = case proxy:
    of "": newAsyncHttpClient()
    else: newAsyncHttpClient(proxy = newProxy(proxy))
  result = await http.getContent(url)

proc post*(url: string, body: string): Future[string] {.async.} =
  ## fetch the content of a given `url` with a POST request (asynchronously)
  let http = case proxy:
    of "": newAsyncHttpClient()
    else: newAsyncHttpClient(proxy = newProxy(proxy))
  http.headers = newHttpHeaders({ "Content-Type": "application/json" })
  result = await http.postContent(url, body)