sub init()
    m.rowFocus = m.top.findNode("rowFocus")
    m.rowBar   = m.top.findNode("rowBar")
    m.numBg    = m.top.findNode("numBg")
    m.num      = m.top.findNode("num")
    m.name     = m.top.findNode("name")
    m.meta     = m.top.findNode("meta")
    m.live     = m.top.findNode("live")
end sub

sub _render()
    c = m.top.itemContent
    if c = invalid then return
    m.name.text = c.title
    m.meta.text = c.description
    num = ""
    if c.hasField("chNum") then num = c.chNum
    m.num.text      = num
    m.numBg.visible = (num <> "")
    online = true
    if c.hasField("chLive") then online = c.chLive
    if online then
        m.live.text  = "● EN VIVO"
        m.live.color = "#CC1F1F"
    else
        m.live.text  = "● FUERA"
        m.live.color = "#6B7280"
    end if
end sub

sub _onFocus()
    p = m.top.focusPercent
    m.rowFocus.opacity = p
    m.rowBar.opacity   = p
end sub
