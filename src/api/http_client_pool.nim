import std/[asyncdispatch, deques, options, httpclient, os, strformat]

export httpclient # for AsyncResponse

let
  ## http(s) proxy read from environment variables.
  proxy =
    if existsEnv("http_proxy"): getEnv("http_proxy")
    elif existsEnv("https_proxy"): getEnv("https_proxy")
    else: ""

#[
  Wrapping AsyncHttpClient for pooling and timeout, also see
  https://github.com/nim-lang/Nim/issues/7413
]#

type
  ## Use this when the number of resource is pre-defined
  ## and have to dequeue before use and enqueue afterward
  ResourcePool*[T] = object
    resources: Deque[T]
    queuers: Deque[Future[T]]

proc rlen*[T](pool: ResourcePool[T]): int =
  pool.resources.len

proc qlen*[T](pool: ResourcePool[T]): int =
  pool.queuers.len

proc dequeue*[T](pool: var ResourcePool[T]): Future[T] =
  ## Take one resource from pool. Wait if not available
  result = newFuture[T]("ResourcePool.dequeue")
  if pool.resources.len == 0:
    pool.queuers.addLast result
  else:
    result.complete pool.resources.popFirst()

proc tryDequeue*[T](pool: var ResourcePool[T]): Option[T] =
  ## Take one resource from pool. Do not wait if not available.
  if pool.resources.len == 0:
    result = none[T]()
  else:
    result = some pool.resources.popFirst()

proc enqueue*[T](pool: var ResourcePool[T], item: T) =
  ## Add one resource to pool.
  if pool.queuers.len > 0:
    pool.queuers.popFirst().complete(item)
  else:
    pool.resources.addLast(item)

type
  RequestTimeoutError* = object of CatchableError

  HttpClientPool* = ref object
    size: int
    clients: ResourcePool[AsyncHttpClient]

proc newHttpClientPool*(size: int): HttpClientPool =
  result.new()
  result.size = size
  result.clients = ResourcePool[AsyncHttpClient]()
  for i in 1..size:
    let client = case proxy:
        of "": newAsyncHttpClient()
        else: newAsyncHttpClient(proxy = newProxy(proxy))
    client.headers = newHttpHeaders({"Content-Type": "application/json"})
    result.clients.enqueue client

proc size*(pool: HttpClientPool): int =
  pool.size

proc len*(pool: HttpClientPool): int =
  pool.clients.rlen

proc request*(
  pool: HttpClientPool,
  url: string,
  httpMethod: HttpMethod,
  body = "",
  headers: HttpHeaders = nil,
  multipart: MultipartData = nil,
  timeout = 5000,
): Future[AsyncResponse] {.async.} =
  let client = await pool.clients.dequeue()
  defer: pool.clients.enqueue(client)
  let fut = newFuture[AsyncResponse]("request")
  proc cb1(fut1: Future[AsyncResponse]) =
    if not fut.finished:
      if fut1.failed: fut.fail(fut1.readError())
      else: fut.complete(fut1.read())
  proc cb2(fut2: Future[void]) =
    if not fut.finished:
      client.close()
      fut.fail newException(RequestTimeoutError, fmt"timeout={timeout}ms")
  let fut1 = client.request(url, httpMethod, body, headers, multipart)
  let fut2 = sleepAsync(timeout)
  fut1.addCallback cb1
  fut2.addCallback cb2
  return await fut

proc responseContent(resp: AsyncResponse): Future[string] {.async.} =
  ## Returns the content of a response as a string.
  ##
  ## A ``HttpRequestError`` will be raised if the server responds with a
  ## client error (status code 4xx) or a server error (status code 5xx).
  if resp.code.is4xx or resp.code.is5xx:
    raise newException(HttpRequestError, resp.status)
  else:
    return await resp.bodyStream.readAll()

proc head*(client: HttpClient | AsyncHttpClient,
          url: string): Future[Response | AsyncResponse] {.multisync.} =
  ## Connects to the hostname specified by the URL and performs a HEAD request.
  ##
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpHead)

proc get*(client: HttpClientPool,
          url: string): Future[AsyncResponse] {.async.} =
  ## Connects to the hostname specified by the URL and performs a GET request.
  ##
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpGet)

proc getContent*(client: HttpClientPool,
                 url: string): Future[string] {.async.} =
  ## Connects to the hostname specified by the URL and returns the content of a GET request.
  let resp = await get(client, url)
  return await responseContent(resp)

proc delete*(client: HttpClientPool,
             url: string): Future[AsyncResponse] {.async.} =
  ## Connects to the hostname specified by the URL and performs a DELETE request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpDelete)

proc deleteContent*(client: HttpClientPool,
                    url: string): Future[string] {.async.} =
  ## Connects to the hostname specified by the URL and returns the content of a DELETE request.
  let resp = await delete(client, url)
  return await responseContent(resp)

proc post*(client: HttpClientPool, url: string, body = "",
           multipart: MultipartData = nil): Future[AsyncResponse]
           {.async.} =
  ## Connects to the hostname specified by the URL and performs a POST request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpPost, body, multipart=multipart)

proc postContent*(client: HttpClientPool, url: string, body = "",
                  multipart: MultipartData = nil): Future[string]
                  {.async.} =
  ## Connects to the hostname specified by the URL and returns the content of a POST request.
  let resp = await post(client, url, body, multipart)
  return await responseContent(resp)

proc put*(client: HttpClientPool, url: string, body = "",
          multipart: MultipartData = nil): Future[AsyncResponse]
          {.async.} =
  ## Connects to the hostname specified by the URL and performs a PUT request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpPut, body, multipart=multipart)

proc putContent*(client: HttpClientPool, url: string, body = "",
                 multipart: MultipartData = nil): Future[string] {.async.} =
  ## Connects to the hostname specified by the URL andreturns the content of a PUT request.
  let resp = await put(client, url, body, multipart)
  return await responseContent(resp)

proc patch*(client: HttpClientPool, url: string, body = "",
            multipart: MultipartData = nil): Future[AsyncResponse]
            {.async.} =
  ## Connects to the hostname specified by the URL and performs a PATCH request.
  ## This procedure uses httpClient values such as ``client.maxRedirects``.
  result = await client.request(url, HttpPatch, body, multipart=multipart)

proc patchContent*(client: HttpClientPool, url: string, body = "",
                   multipart: MultipartData = nil): Future[string]
                  {.async.} =
  ## Connects to the hostname specified by the URL and returns the content of a PATCH request.
  let resp = await patch(client, url, body, multipart)
  return await responseContent(resp)