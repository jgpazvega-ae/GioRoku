sub init()
    m.chanList   = m.top.findNode("chanList")
    m.countLabel = m.top.findNode("countLabel")
    m.clock      = m.top.findNode("clock")
    m.emptyMsg   = m.top.findNode("emptyMsg")

    m.chanList.observeField("itemSelected", "_onItemSelected")
    m.chanList.observeField("itemFocused",  "_onItemFocused")

    m.clockTimer = createObject("roSGNode", "Timer")
    m.clockTimer.duration = 1
    m.clockTimer.repeat   = true
    m.clockTimer.observeField("fire", "_tick")
    m.clockTimer.control  = "start"
    _tick()
end sub

sub _onChannelData()
    content = m.top.channelData
    if content = invalid then return

    n = content.getChildCount()
    m.chanList.content = content
    if n > 0 then
        m.countLabel.text  = n.toStr() + " canales"
        m.emptyMsg.visible = false
        m.chanList.setFocus(true)
    else
        m.countLabel.text  = "Sin canales"
        m.emptyMsg.text    = "Aún no hay canales." + chr(10) + "Importa una lista M3U desde la herramienta web."
        m.emptyMsg.visible = true
    end if
end sub

sub _onItemFocused()
    ' Nothing extra needed — GuideRow handles its own highlight via focusPercent
end sub

sub _onItemSelected()
    idx = m.chanList.itemSelected
    content = m.top.channelData
    if content = invalid then return
    if idx < 0 or idx >= content.getChildCount() then return
    item = content.getChild(idx)
    if item <> invalid then m.top.playItem = item
end sub

sub _tick()
    m.clock.text = _clockStr()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left" then
        m.top.navigate = "sidebar"
        return true
    else if key = "right" then
        m.top.navigate = "guide"
        return true
    else if key = "back" then
        m.top.navigate = "home"
        return true
    else if key = "options" then
        idx = m.chanList.itemFocused
        content = m.top.channelData
        if content <> invalid and idx >= 0 and idx < content.getChildCount() then
            item = content.getChild(idx)
            if item <> invalid and item.hasField("chId") then
                id = item.chId
                if _isFav(id) then _removeFav(id) else _addFav(id)
            end if
        end if
        return true
    end if
    return false
end function
