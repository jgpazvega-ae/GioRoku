sub init()
    m.cardBg       = m.top.findNode("cardBg")
    m.focusBg      = m.top.findNode("focusBg")
    m.logo         = m.top.findNode("logo")
    m.logoFallback = m.top.findNode("logoFallback")
    m.logoInit     = m.top.findNode("logoInit")
    m.name         = m.top.findNode("name")
end sub

sub _render()
    c = m.top.itemContent
    if c = invalid then return
    m.name.text = c.title

    uri = ""
    if c.hdPosterUrl <> invalid then uri = c.hdPosterUrl
    if uri <> "" then
        m.logo.uri             = uri
        m.logo.visible         = true
        m.logoFallback.visible = false
        m.logoInit.visible     = false
    else
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
end sub

sub _onFocus()
    p = m.top.focusPercent
    m.focusBg.opacity = p * 0.15
end sub
