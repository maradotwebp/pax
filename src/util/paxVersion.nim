## Helper file for retrieving pax version from latest tag

import strutils

const currentPaxVersion*: string = staticExec("git describe --tags HEAD").split("-")[0]
