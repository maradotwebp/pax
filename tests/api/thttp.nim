import asyncdispatch
import api/http

block: # get with successful response
  discard waitFor(get("http://httpbin.org/get".Url))

block: # get with non-existing website
  doAssertRaises(OSError):
    discard waitFor(get("http://non-existing-website.web".Url))

block: # get on endpoint that does not support get
  doAssertRaises(HttpRequestError):
    discard waitFor(get("http://httpbin.org/post".Url))

block: # post with successful response
  discard waitFor(post("http://httpbin.org/post".Url))

block: # post with non-existing website
  doAssertRaises(OSError):
    discard waitFor(post("http://non-existing-website.web".Url))

block: # post on endpoint that does not support get
  doAssertRaises(HttpRequestError):
    discard waitFor(post("http://httpbin.org/get".Url))