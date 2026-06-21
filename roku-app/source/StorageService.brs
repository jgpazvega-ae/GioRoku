' Registry-backed storage for favorites, recents, and settings.

function _regRead(key as string) as dynamic
    reg = createObject("roRegistrySection", "GioRoku")
    if reg.exists(key) then return reg.read(key)
    return invalid
end function

sub _regWrite(key as string, value as string)
    reg = createObject("roRegistrySection", "GioRoku")
    reg.write(key, value)
    reg.flush()
end sub

function _getFavorites() as object
    raw = _regRead("favorites")
    if raw = invalid or raw = "" then return []
    parsed = parseJSON(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

function _isFav(id as string) as boolean
    for each f in _getFavorites()
        if f = id then return true
    end for
    return false
end function

sub _addFav(id as string)
    favs = _getFavorites()
    for each f in favs
        if f = id then return
    end for
    favs.push(id)
    _regWrite("favorites", formatJSON(favs))
end sub

sub _removeFav(id as string)
    out = []
    for each f in _getFavorites()
        if f <> id then out.push(f)
    end for
    _regWrite("favorites", formatJSON(out))
end sub

sub _addRecent(id as string)
    raw = _regRead("recentChannels")
    arr = []
    if raw <> invalid and raw <> "" then
        p = parseJSON(raw)
        if type(p) = "roArray" then arr = p
    end if
    out = [id]
    for each r in arr
        if r <> id and out.count() < 20 then out.push(r)
    end for
    _regWrite("recentChannels", formatJSON(out))
end sub

function _getRecent() as object
    raw = _regRead("recentChannels")
    if raw = invalid or raw = "" then return []
    parsed = parseJSON(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

function _getSettings() as object
    raw      = _regRead("settings")
    defaults = {parentalEnabled: false}
    if raw = invalid or raw = "" then return defaults
    p = parseJSON(raw)
    if type(p) <> "roAssociativeArray" then return defaults
    for each k in defaults
        if p[k] = invalid then p[k] = defaults[k]
    end for
    return p
end function

sub _setSetting(key as string, value as dynamic)
    s      = _getSettings()
    s[key] = value
    _regWrite("settings", formatJSON(s))
end sub

sub _clearStorage()
    _regWrite("favorites",      "[]")
    _regWrite("recentChannels", "[]")
end sub
