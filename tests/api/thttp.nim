discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"
"""

import asyncdispatch, api/http

block: # fetch
  let googleHttpsReq = fetch("https://www.google.com")
  let googleHttpReq = fetch("http://www.google.com")
  let exampleReq = fetch("https://example.com")
  waitFor(googleHttpsReq and googleHttpReq and exampleReq)
