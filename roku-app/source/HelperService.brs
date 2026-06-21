' Shared helper functions included by all screen components via <script> tags.

function _str(aa as object, key as string) as string
    if aa = invalid then return ""
    if type(aa) <> "roAssociativeArray" then return ""
    if not aa.DoesExist(key) then return ""
    v = aa[key]
    if v = invalid then return ""
    if type(v) = "String" or type(v) = "roString" then return v
    return v.toStr()
end function

function _displayName(ch as object) as string
    name = _str(ch, "name")
    if name = "" then name = _str(ch, "title")
    out  = ""
    depth = 0
    for i = 0 to len(name) - 1
        c = mid(name, i + 1, 1)
        if c = "(" or c = "[" then
            depth = depth + 1
        else if c = ")" or c = "]" then
            if depth > 0 then depth = depth - 1
        else if depth = 0 then
            out = out + c
        end if
    end for
    out = out.trim()
    while instr(1, out, "  ") > 0
        out = _replaceAll(out, "  ", " ")
    end while
    if out = "" then return name
    return out
end function

function _replaceAll(s as string, find as string, repl as string) as string
    out  = ""
    rest = s
    at   = instr(1, rest, find)
    while at > 0
        out  = out + left(rest, at - 1) + repl
        rest = mid(rest, at + len(find))
        at   = instr(1, rest, find)
    end while
    return out + rest
end function

function iif(cond as boolean, a as dynamic, b as dynamic) as dynamic
    if cond then return a
    return b
end function

function _clockStr() as string
    dt = createObject("roDateTime")
    dt.toLocalTime()
    h  = dt.getHours()
    mi = dt.getMinutes()
    ampm = "a.m."
    h12  = h
    if h >= 12 then ampm = "p.m."
    if h12 = 0  then h12 = 12
    if h12 > 12 then h12 = h12 - 12
    mm = mi.toStr()
    if len(mm) < 2 then mm = "0" + mm
    return h12.toStr() + ":" + mm + " " + ampm
end function

function _pad3(n as integer) as string
    s = n.toStr()
    while len(s) < 3
        s = "0" + s
    end while
    return s
end function
