import macros
import term

macro prefixEcho(callee: untyped; pre: string; args: varargs[untyped]): untyped =
  ## prefix calls to echo with a string
  result = newCall(callee)
  result.add pre
  for i in 0 ..< args.len:
    result.add args[i]

template echoDebug*(args: varargs[string, `$`]): void = prefixEcho(echo, debugIcon & " ", args)
template echoInfo*(args: varargs[string, `$`]): void = prefixEcho(echo, infoIcon & " ", args)
template echoWarn*(args: varargs[string, `$`]): void = prefixEcho(echo, warnIcon & " ", args)
template echoError*(args: varargs[string, `$`]): void = prefixEcho(echo, errorIcon & " ", args)
template echoRoot*(args: varargs[string, `$`]): void = prefixEcho(echo, rootIcon & " ", args)