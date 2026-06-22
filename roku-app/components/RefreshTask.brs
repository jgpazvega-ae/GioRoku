sub init()
    m.top.functionName = "run"
end sub

sub run()
    ' Pull the same roku-app/data/channels.json committed daily by the pipeline.
    ' This is the clean, LATAM-only, name-filtered list — NOT the unfiltered
    ' GitHub Pages API that previously injected 12,000 international channels.
    url = "https://raw.githubusercontent.com/jgpazvega-ae/GioRoku/main/roku-app/data/channels.json"

    port = createObject("roMessagePort")
    http = createObject("roUrlTransfer")
    http.setUrl(url)
    http.addHeader("User-Agent", "GioRoku/1.0")
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()
    http.setMessagePort(port)

    if not http.asyncGetToString() then
        m.top.status = "request_failed"
        return
    end if

    msg = wait(15000, port)
    if msg = invalid or type(msg) <> "roUrlEvent" then
        http.asyncCancel()
        m.top.status = "timeout"
        return
    end if

    code = msg.getResponseCode()
    if code <> 200 then
        m.top.status = "http_" + code.toStr()
        return
    end if

    body = msg.getString()
    if body = "" or body = invalid then
        m.top.status = "empty"
        return
    end if

    m.top.result = body
    m.top.status = "ok"
end sub
