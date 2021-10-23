## Helper Utilities for easier scripting & code flow management.

template returnIf*(assertion: bool): void =
  ## returns if `assertion` is true
  if assertion: return

template returnIfNot*(assertion: bool): void =
  ## returns if `assertion` is false
  if not assertion: return