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

function _countryLabel(country as string) as string
    if country = "MX"    then return "México"
    if country = "CL"    then return "Chile"
    if country = "PE"    then return "Perú"
    if country = "AR"    then return "Argentina"
    if country = "CO"    then return "Colombia"
    if country = "INTL"  then return "Internacional"
    if country = "US_ES" then return "EE.UU. en Español"
    if country = "EC"    then return "Ecuador"
    if country = "BO"    then return "Bolivia"
    if country = "VE"    then return "Venezuela"
    if country = "US"    then return "Estados Unidos"
    if country = "UK"    then return "Reino Unido"
    if country = "CA"    then return "Canadá"
    if country = "AU"    then return "Australia"
    if country = "DE"    then return "Alemania"
    if country = "FR"    then return "Francia"
    if country = "JP"    then return "Japón"
    if country = "TR"    then return "Turquía"
    if country = "CN"    then return "China"
    return country
end function

function _countryColor(country as string) as string
    if country = "MX"    then return "#16A34A"
    if country = "CL"    then return "#2563EB"
    if country = "PE"    then return "#DC2626"
    if country = "AR"    then return "#38BDF8"
    if country = "CO"    then return "#F59E0B"
    if country = "INTL"  then return "#8B5CF6"
    if country = "US_ES" then return "#7C3AED"
    if country = "EC"    then return "#FBBF24"
    if country = "BO"    then return "#EF4444"
    if country = "VE"    then return "#FB923C"
    return "#374151"
end function

function _categoryColor(cat as string) as string
    cat = lcase(cat)
    if cat = "news"          then return "#EF4444"
    if cat = "sports"        then return "#10B981"
    if cat = "movies"        then return "#8B5CF6"
    if cat = "music"         then return "#EC4899"
    if cat = "kids"          then return "#F59E0B"
    if cat = "documentary"   then return "#14B8A6"
    if cat = "lifestyle"     then return "#6366F1"
    if cat = "entertainment" then return "#3B82F6"
    return "#374151"
end function
