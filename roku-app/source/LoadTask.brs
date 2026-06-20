sub init()
    m.top.functionName = "fetch"
end sub

sub fetch()
    base = m.top.baseUrl
    page = _fetchJSON(base + "/channels/page/1.json")
    if page = invalid
        m.top.taskState = "error"
        return
    end if

    list = []
    if page.DoesExist("channels") and page.channels <> invalid
        for each ch in page.channels
            list.push(ch)
        end for
    end if

    totalPages = 1
    if page.DoesExist("totalPages") then totalPages = page.totalPages
    last = totalPages
    if last > 10 then last = 10
    for p = 2 to last
        extra = _fetchJSON(base + "/channels/page/" + p.toStr() + ".json")
        if extra <> invalid and extra.DoesExist("channels") and extra.channels <> invalid
            for each ch in extra.channels
                list.push(ch)
            end for
        end if
    end for

    m.top.channels = list
    m.top.taskState = "done"
end sub

function _fetchJSON(url as string) as dynamic
    req = createObject("roUrlTransfer")
    req.setUrl(url)
    req.enableHostVerification(false)
    req.enablePeerVerification(false)
    req.addHeader("Accept", "application/json")
    req.addHeader("User-Agent", "GioRoku/1.0")
    resp = req.getToString()
    if resp = invalid or resp = "" then return invalid
    return parseJSON(resp)
end function
