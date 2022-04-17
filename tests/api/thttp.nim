import std/asyncdispatch
import api/http
import ../tutils

asyncBlock: # get with successful response
  discard await get("http://httpbin.org/get".Url)

asyncBlock: # get with non-existing website
  doAssertRaises(OSError):
    discard await get("http://non-existing-website.web".Url)

asyncBlock: # get on endpoint that does not support get
  doAssertRaises(HttpRequestError):
    discard await get("http://httpbin.org/post".Url)

asyncBlock: # post with successful response
  discard await post("http://httpbin.org/post".Url)

asyncBlock: # post with non-existing website
  doAssertRaises(OSError):
    discard await post("http://non-existing-website.web".Url)

asyncBlock: # post on endpoint that does not support get
  doAssertRaises(HttpRequestError):
    discard await post("http://httpbin.org/get".Url)

runTests()