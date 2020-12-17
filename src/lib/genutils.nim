proc `??`*[A](x: A, y: A): A =
  ## returns y if x is not defined
  if x is nil: y else: x

proc `??`*(x: string, y: string): string =
  ## return y if x is not defined
  if x == "": y else: x

proc `?`*[A](c: bool, t: (A, A)): A =
  ## return the first element if condition is true, otherwise the second
  if c: t[0] else: t[1]