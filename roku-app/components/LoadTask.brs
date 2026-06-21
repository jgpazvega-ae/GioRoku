sub init()
    m.top.functionName = "fetch"
end sub

sub fetch()
    base = m.top.baseUrl
    page = _fetchJSON(base + "/channels/page/1.json")
    if page = invalid then
        m.top.result    = {channels: []}
        m.top.taskState = "error"
        return
    end if

    list = []
    if page.DoesExist("channels") and page.channels <> invalid then
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
        if extra <> invalid and extra.DoesExist("channels") and extra.channels <> invalid then
            for each ch in extra.channels
                list.push(ch)
            end for
        end if
    end for

    m.top.result    = {channels: list}
    m.top.taskState = "done"
end sub

' Hard-timeout fetch: AsyncGetToString + wait() with a timeout ALWAYS
' returns within the limit, even if the connection hangs. This is what
' guarantees the splash never stalls on an unreachable network.
function _fetchJSON(url as string) as dynamic
    port = createObject("roMessagePort")
    req  = createObject("roUrlTransfer")
    req.setPort(port)
    req.setUrl(url)
    req.enableHostVerification(false)
    req.enablePeerVerification(false)
    req.addHeader("Accept", "application/json")
    req.addHeader("User-Agent", "GioRoku/1.0")

    if not req.asyncGetToString() then return invalid

    msg = wait(8000, port)   ' 8s hard cap per request
    if msg = invalid then
        req.asyncCancel()
        return invalid
    end if

    if type(msg) = "roUrlEvent" then
        if msg.getResponseCode() = 200 then
            resp = msg.getString()
            if resp = "" then return invalid
            return parseJSON(resp)
        end if
    end if
    return invalid
end function
