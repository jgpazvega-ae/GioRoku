sub init()
    m.favList    = m.top.findNode("favList")
    m.countLabel = m.top.findNode("countLabel")
    m.emptyMsg   = m.top.findNode("emptyMsg")

    m.favList.observeField("itemSelected", "_onItemSelected")
end sub

sub _onChannelData()
    content = m.top.channelData
    if content = invalid then return
    n = content.getChildCount()
    m.favList.content = content
    if n > 0 then
        m.countLabel.text  = n.toStr() + iif(n = 1, " canal", " canales")
        m.emptyMsg.visible = false
        m.favList.setFocus(true)
    else
        m.countLabel.text  = ""
        m.emptyMsg.visible = true
    end if
end sub

sub _onItemSelected()
    idx     = m.favList.itemSelected
    content = m.top.channelData
    if content = invalid then return
    if idx < 0 or idx >= content.getChildCount() then return
    item = content.getChild(idx)
    if item <> invalid then m.top.playItem = item
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left" then
        m.top.navigate = "sidebar"
        return true
    else if key = "back" then
        m.top.navigate = "home"
        return true
    else if key = "options" then
        idx     = m.favList.itemFocused
        content = m.top.channelData
        if content <> invalid and idx >= 0 and idx < content.getChildCount() then
            item = content.getChild(idx)
            if item <> invalid and item.hasField("chId") then
                _removeFav(item.chId)
            end if
        end if
        return true
    end if
    return false
end function
