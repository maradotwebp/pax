## A simple wrapper for the `httpclient` module.
## Used for convenience over creating a `newAsyncHttpClient()` instance.

import std/[asyncdispatch, httpclient]
import http_client_pool
export HttpRequestError

let
  ## http client pool
  ## set to 1 for now, because more cause race conditions.
  clients = newHttpClientPool(1)

type
  ## an URL to which a http request can be made.
  Url* = distinct string

proc `$`(v: Url): string {.borrow.}

proc get*(url: Url): Future[string] {.async.} =
  ## creates a GET request targeting the given `url`.
  ## throws OSError or HttpRequestError if the request failed.
  ## returns the body of the response.
  result = await clients.getContent($url)

proc post*(url: Url, body: string = ""): Future[string] {.async.} =
  ## creates a POST request targeting the given `url`, with an optional `body`.
  ## throws OSError or HttpRequestError if the request failed.
  ## returns the body of the response.
  result = await clients.postContent($url, body)
