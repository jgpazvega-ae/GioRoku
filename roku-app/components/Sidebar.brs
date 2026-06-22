sub init()
    m.sels = []
    m.bars = []
    m.lbls = []
    for i = 0 to 5
        m.sels.push(m.top.findNode("sel" + i.toStr()))
        m.bars.push(m.top.findNode("bar" + i.toStr()))
        m.lbls.push(m.top.findNode("lbl" + i.toStr()))
    end for
    m.focusIdx = 0
    _updateUI()
end sub

sub _onActiveItem()
    m.focusIdx = m.top.activeItem
    _updateUI()
end sub

sub _updateUI()
    active = m.top.activeItem
    for i = 0 to 5
        if i = m.focusIdx then
            m.sels[i].opacity = 1
            m.bars[i].opacity = 1
            m.lbls[i].color   = "#FFFFFF"
        else if i = active then
            m.sels[i].opacity = 0
            m.bars[i].opacity = 0.5
            m.lbls[i].color   = "#CC1F1F"
        else
            m.sels[i].opacity = 0
            m.bars[i].opacity = 0
            m.lbls[i].color   = "#9CA3AF"
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    dests = ["home", "livetv", "english", "favorites", "search", "settings"]
    if key = "up" then
        m.focusIdx = (m.focusIdx - 1 + 6) mod 6
        _updateUI()
        return true
    else if key = "down" then
        m.focusIdx = (m.focusIdx + 1) mod 6
        _updateUI()
        return true
    else if key = "OK" or key = "right" then
        m.top.navigate = dests[m.focusIdx]
        return true
    else if key = "back" or key = "left" then
        m.top.navigate = "close"
        return true
    end if
    return false
end function
