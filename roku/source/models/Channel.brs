' Channel model helper functions

function createChannel(data as Object) as Object
    ch = {}
    ch.id = _str(data, "id", "")
    ch.name = _str(data, "name", "Canal")
    ch.logo = _str(data, "logo", "")
    ch.category = _str(data, "category", "entertainment")
    ch.categoryLabel = _str(data, "categoryLabel", "Entretenimiento")
    ch.country = _str(data, "country", "INTL")
    ch.countryLabel = _str(data, "countryLabel", "Internacional")
    ch.language = _str(data, "language", "es")
    ch.streamUrl = _str(data, "streamUrl", "")
    ch.quality = _str(data, "quality", "SD")
    ch.isOnline = _bool(data, "isOnline", true)
    ch.isEnabled = _bool(data, "isEnabled", true)
    ch.isFeatured = _bool(data, "isFeatured", false)
    ch.epgId = _str(data, "epgId", "")
    ch.offlineCount = _int(data, "offlineCount", 0)
    ch.backupUrls = []
    if data.DoesExist("backupUrls") and type(data.backupUrls) = "roArray" then
        ch.backupUrls = data.backupUrls
    end if
    ch.tags = []
    if data.DoesExist("tags") and type(data.tags) = "roArray" then
        ch.tags = data.tags
    end if
    ch.currentProgram = invalid
    if data.DoesExist("currentProgram") then ch.currentProgram = data.currentProgram
    ch.nextProgram = invalid
    if data.DoesExist("nextProgram") then ch.nextProgram = data.nextProgram
    return ch
end function

function isOnline(channel as Object) as Boolean
    if channel.DoesExist("isOnline") then return channel.isOnline
    return true
end function

function getDisplayName(channel as Object) as String
    if channel.DoesExist("name") and channel.name <> "" then return channel.name
    return "Canal"
end function

function getLogoUrl(channel as Object) as String
    if channel.DoesExist("logo") and channel.logo <> "" then return channel.logo
    return ""
end function

' Private helpers
function _str(data as Object, key as String, default as String) as String
    if data.DoesExist(key) and data[key] <> invalid then return data[key].toStr()
    return default
end function

function _bool(data as Object, key as String, default as Boolean) as Boolean
    if data.DoesExist(key) then return data[key] = true
    return default
end function

function _int(data as Object, key as String, default as Integer) as Integer
    if data.DoesExist(key) and data[key] <> invalid then return Int(data[key])
    return default
end function
