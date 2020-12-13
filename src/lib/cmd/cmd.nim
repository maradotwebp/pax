type
  File* = object
    projectId*: int
    fileId*: int

  Project* = object
    name*: string
    author*: string
    version*: string
    mcVersion*: string
    mcModloaderId*: string
    files*: seq[File]