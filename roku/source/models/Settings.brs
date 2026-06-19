' Settings model — default values and accessors

function DEFAULT_SETTINGS() as Object
    return {
        theme: "dark",
        countryPref: "ALL",
        parentalEnabled: false,
        textSize: "normal"
    }
end function

function getTheme(storage as Object) as String
    s = storage.getSettings()
    if s.DoesExist("theme") then return s.theme
    return "dark"
end function

function getCountryPref(storage as Object) as String
    s = storage.getSettings()
    if s.DoesExist("countryPref") then return s.countryPref
    return "ALL"
end function

function isParentalEnabled(storage as Object) as Boolean
    s = storage.getSettings()
    if s.DoesExist("parentalEnabled") then return s.parentalEnabled = true
    return false
end function
