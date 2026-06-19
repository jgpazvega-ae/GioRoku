' APIService.brs — Fetches data from the GioRoku GitHub Pages JSON API

function APIService_Init() as object
    svc = {}
    svc.BASE_URL = "https://jgpazvega-ae.github.io/GioRoku/api/v1"
    svc.fetchStatus     = APIService_fetchStatus
    svc.fetchPage       = APIService_fetchPage
    svc.fetchCountry    = APIService_fetchCountry
    svc.fetchCategory   = APIService_fetchCategory
    svc.fetchCategories = APIService_fetchCategories
    svc.fetchCountries  = APIService_fetchCountries
    svc.fetchEPG        = APIService_fetchEPG
    svc._get            = APIService_get
    return svc
end function

function APIService_fetchStatus() as dynamic
    return m._get("/status.json")
end function

function APIService_fetchPage(page as integer) as dynamic
    return m._get("/channels/page/" + str(page).trim() + ".json")
end function

function APIService_fetchCountry(code as string) as dynamic
    return m._get("/channels/country/" + code + ".json")
end function

function APIService_fetchCategory(slug as string) as dynamic
    return m._get("/channels/category/" + slug + ".json")
end function

function APIService_fetchCategories() as dynamic
    return m._get("/categories.json")
end function

function APIService_fetchCountries() as dynamic
    return m._get("/countries.json")
end function

function APIService_fetchEPG() as dynamic
    return m._get("/epg.json")
end function

function APIService_get(path as string) as dynamic
    url = m.BASE_URL + path
    req = createObject("roUrlTransfer")
    req.setUrl(url)
    req.enableHostVerification(false)
    req.enablePeerVerification(false)
    req.addHeader("Accept", "application/json")
    req.addHeader("User-Agent", "GioRoku/1.0 Roku")
    response = req.getToString()
    if response = "" or response = invalid
        return invalid
    end if
    return parseJSON(response)
end function
