## A simple wrapper for the `httpclient` module.
## Used for convenience over creating a `newAsyncHttpClient()` instance.

import asyncdispatch, httpclient, os
export HttpRequestError

let
  ## http(s) proxy read from environment variables.
  proxy =
    if existsEnv("http_proxy"): getEnv("http_proxy")
    elif existsEnv("https_proxy"): getEnv("https_proxy")
    else: ""

type
  ## an URL to which a http request can be made.
  Url* = distinct string

proc `$`(v: Url): string {.borrow.}

proc getHttpClient(): AsyncHttpClient =
  ## returns an async http client using the proxy (if it exists).
  let http = case proxy:
    of "": newAsyncHttpClient()
    else: newAsyncHttpClient(proxy = newProxy(proxy))
  http.headers = newHttpHeaders({"Content-Type": "application/json"})
  return http

proc get*(url: Url): Future[string] {.async.} =
  ## creates a GET request targeting the given `url`.
  ## throws OSError or HttpRequestError if the request failed.
  ## returns the body of the response.
  let http = getHttpClient()
  return await http.getContent($url)

proc post*(url: Url, body: string = ""): Future[string] {.async.} =
  ## creates a POST request targeting the given `url`, with an optional `body`.
  ## throws OSError or HttpRequestError if the request failed.
  ## returns the body of the response.
  let http = getHttpClient()
  return await http.postContent($url, body)
