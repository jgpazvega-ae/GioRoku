sub init()
    m.rowFocus    = m.top.findNode("rowFocus")
    m.rowBar      = m.top.findNode("rowBar")
    m.numBg       = m.top.findNode("numBg")
    m.num         = m.top.findNode("num")
    m.logo        = m.top.findNode("logo")
    m.logoFallback = m.top.findNode("logoFallback")
    m.logoInit    = m.top.findNode("logoInit")
    m.name        = m.top.findNode("name")
    m.meta        = m.top.findNode("meta")
    m.live        = m.top.findNode("live")
end sub

sub _render()
    c = m.top.itemContent
    if c = invalid then return
    m.name.text = c.title
    m.meta.text = c.description

    uri = ""
    if c.hdPosterUrl <> invalid then uri = c.hdPosterUrl
    if uri <> "" then
        m.logo.uri             = uri
        m.logo.visible         = true
        m.logoFallback.visible = false
        m.logoInit.visible     = false
    else
        m.logo.uri             = ""
        m.logo.visible         = false
        col = "#374151"
        if c.hasField("chColor") and c.chColor <> invalid and c.chColor <> "" then col = c.chColor
        m.logoFallback.color   = col
        m.logoFallback.visible = true
        init = "?"
        if c.title <> invalid and c.title <> "" then init = ucase(left(c.title, 1))
        m.logoInit.text        = init
        m.logoInit.visible     = true
    end if

    num = ""
    if c.hasField("chNum") then num = c.chNum
    m.num.text         = num
    m.numBg.visible    = (num <> "")
    online = true
    if c.hasField("chLive") then online = c.chLive
    if online then
        m.live.text  = "● EN VIVO"
        m.live.color = "#CC1F1F"
    else
        m.live.text  = "● FUERA DE LÍNEA"
        m.live.color = "#6B7280"
    end if
end sub

sub _onFocus()
    p = m.top.focusPercent
    m.rowFocus.opacity = p
    m.rowBar.opacity   = p
end sub
