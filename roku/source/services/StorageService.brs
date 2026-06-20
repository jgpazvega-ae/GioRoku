' StorageService.brs — Persists favorites, recent channels and settings

function StorageService_Init() as object
    svc = {}
    svc.SECTION = "GioRoku"
    svc.MAX_RECENT = 20
    svc.getFavorites    = StorageService_getFavorites
    svc.addFavorite     = StorageService_addFavorite
    svc.removeFavorite  = StorageService_removeFavorite
    svc.isFavorite      = StorageService_isFavorite
    svc.getRecent       = StorageService_getRecent
    svc.addRecent       = StorageService_addRecent
    svc.getSettings     = StorageService_getSettings
    svc.setSetting      = StorageService_setSetting
    svc.clearAll        = StorageService_clearAll
    svc._read           = StorageService_read
    svc._write          = StorageService_write
    return svc
end function

function StorageService_getFavorites() as object
    raw = m._read("favorites")
    if raw = invalid or raw = "" then return []
    parsed = parseJSON(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

function StorageService_addFavorite(channelId as string)
    favs = m.getFavorites()
    for each id in favs
        if id = channelId then return
    end for
    favs.push(channelId)
    m._write("favorites", formatJSON(favs))
end function

function StorageService_removeFavorite(channelId as string)
    favs = m.getFavorites()
    newFavs = []
    for each id in favs
        if id <> channelId then newFavs.push(id)
    end for
    m._write("favorites", formatJSON(newFavs))
end function

function StorageService_isFavorite(channelId as string) as boolean
    for each id in m.getFavorites()
        if id = channelId then return true
    end for
    return false
end function

function StorageService_getRecent() as object
    raw = m._read("recentChannels")
    if raw = invalid or raw = "" then return []
    parsed = parseJSON(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

function StorageService_addRecent(channelId as string)
    recent = m.getRecent()
    filtered = []
    for each item in recent
        if item.id <> channelId then filtered.push(item)
    end for
    entry = { id: channelId, watchedAt: "" + createObject("roDateTime").asSeconds() }
    filtered.unshift(entry)
    if filtered.count() > m.MAX_RECENT then filtered.pop()
    m._write("recentChannels", formatJSON(filtered))
end function

function StorageService_getSettings() as object
    raw = m._read("settings")
    defaults = { theme: "dark", countryPref: "", parentalEnabled: false }
    if raw = invalid or raw = "" then return defaults
    parsed = parseJSON(raw)
    if type(parsed) <> "roAssociativeArray" then return defaults
    for each key in defaults
        if parsed[key] = invalid then parsed[key] = defaults[key]
    end for
    return parsed
end function

function StorageService_setSetting(key as string, value as dynamic)
    settings = m.getSettings()
    settings[key] = value
    m._write("settings", formatJSON(settings))
end function

function StorageService_clearAll()
    reg = createObject("roRegistrySection", m.SECTION)
    reg.delete("favorites")
    reg.delete("recentChannels")
    reg.delete("settings")
    reg.flush()
end function

function StorageService_read(key as string) as dynamic
    reg = createObject("roRegistrySection", m.SECTION)
    if reg.exists(key) then return reg.read(key)
    return invalid
end function

function StorageService_write(key as string, value as string)
    reg = createObject("roRegistrySection", m.SECTION)
    reg.write(key, value)
    reg.flush()
end function
