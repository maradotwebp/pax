discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import asyncdispatch, api/http

block: # fetch
  let exampleReq = fetch("https://example.com")
  discard waitFor(exampleReq)

block: # post
  let apiTestReq = post("https://httpbin.org/post", "{}")
  discard waitFor(apiTestReq)
