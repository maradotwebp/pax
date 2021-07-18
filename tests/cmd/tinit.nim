discard """
  cmd: "nim $target --hints:on -d:testing -d:ssl --nimblePath:tests/deps $options $file"

  input: '''
y
-
y
-
y
testmodpack
testauthor
1.0.0
1.16.4
forge
-
y
testmodpack
testauthor
1.2.3
1.14.4
othermodloader
fabric
-
  '''

  outputsub: '''
Are you sure you want to the pax project in the current folder? (y/n - default y): [x] The current folder is already a pax project.
 └─ If you are sure you want to overwrite existing files, use the --force option
-
Are you sure you want to the pax project in the current folder? (y/n - default y): [:] Writing .gitignore..
[:] Writing Github CI file..
-
  '''
"""

import json, strutils, os
import cli/clr
import cmd/init

terminalColorEnabledSetting = false

block: # test rejecting existing pax project
  removeDir("./modpack")
  paxInit(force = false, skipManifest = true, skipGit = true)
  createDir("./modpack")
  writeFile("./modpack/manifest.json", "hello :D")
  paxInit(force = false, skipManifest = true, skipGit = true)
  paxInit(force = true, skipManifest = true, skipGit = true)
  doAssert stdin.readLine() == "-"
  echo "-"

block: # init git only
  removeDir("./modpack")
  let existingGithubWorkflow = readFile(".github/workflows/main.yml")
  defer: writeFile(".github/workflows/main.yml", existingGithubWorkflow)
  let existingGitignore = readFile(".gitignore")
  defer: writeFile(".gitignore", existingGitignore)
  let newGithubWorkflow = readFile("src/modpack/templates/main.yml")
  let newGitignore = readFile("src/modpack/templates/.gitignore")
  paxInit(force = false, skipManifest = true, skipGit = false)
  doAssert readFile(".github/workflows/main.yml") == newGithubWorkflow
  doAssert readFile(".gitignore") == newGitignore
  doAssert stdin.readLine() == "-"
  echo "-"

block: # init forge project
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["minecraft"]["version"].getStr == "1.16.4"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr.startsWith("forge")
  doAssert manifest["version"].getStr == "1.0.0"
  doAssert manifest["author"].getStr == "testauthor"
  doAssert manifest["name"].getStr == "testmodpack"
  doAssert stdin.readLine() == "-"
  echo "-"

block: # init fabric project
  removeDir("./modpack")
  paxInit(force = false, skipManifest = false, skipGit = true)
  let manifest = readFile("./modpack/manifest.json").parseJson
  doAssert manifest["minecraft"]["version"].getStr == "1.14.4"
  doAssert manifest["minecraft"]["modLoaders"][0]["id"].getStr.startsWith("fabric")
  doAssert manifest["version"].getStr == "1.2.3"
  doAssert manifest["author"].getStr == "testauthor"
  doAssert manifest["name"].getStr == "testmodpack"
  doAssert stdin.readLine() == "-"
  echo "-"