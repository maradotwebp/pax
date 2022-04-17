import std/[asyncdispatch, asyncfutures]

var tests*: seq[Future[void]] = @[]

template asyncBlock*(body: untyped) =
  block:
    proc test() {.async.} =
      body

    tests.add(test())

proc runTests*(): void =
  waitFor all tests