import ../lib/io/files, ../lib/io/http

proc cmdUpdateDb*(): void =
  ## update local databases of available forge versions
  requirePaxProject

  echoInfo "Updating databases.."
  writeFile(forgeVersionFile, fetch(forgeVersionUrl))