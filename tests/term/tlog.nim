discard """
  output: '''
[:] Hello!
[-] Information here!
[!] Warning, for more interesting messages
[x] An error has occured!
[Δ] Some funky looking root icon
  '''
"""

import term/color, term/log

terminalColorEnabledSetting = false

block: # echos
  echoDebug "Hello!"
  echoInfo "Information here!"
  echoWarn "Warning, for more interesting messages"
  echoError "An error has occured!"
  echoRoot "Some funky looking root icon"