import ../api/cfcache
import ../term/log

proc paxCache*(action: string): void =
  ## clean/purge the cache
  case action:
    of "clean":
      echoInfo "Cleaning cache..."
      let numCleanedItems = cfcache.clean()
      echoInfo "Removed ", numCleanedItems.`$`.fgCyan, " items."
    of "purge":
      echoInfo "Purging cache..."
      cfcache.purge()
      echoInfo "Purged cache."
    else:
      discard