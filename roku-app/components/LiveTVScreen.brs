sub init()
    m.chanList   = m.top.findNode("chanList")
    m.countLabel = m.top.findNode("countLabel")
    m.clock      = m.top.findNode("clock")
    m.emptyMsg   = m.top.findNode("emptyMsg")

    m.chanList.observeField("rowItemSelected", "_onItemSelected")

    m.clockTimer = createObject("roSGNode", "Timer")
    m.clockTimer.duration = 30
    m.clockTimer.repeat   = true
    m.clockTimer.observeField("fire", "_tick")
    m.clockTimer.control  = "start"
    _tick()
end sub

sub _onChannelData()
    content = m.top.channelData
    if content = invalid then return

    ' Count total channels across all country rows
    total = 0
    for r = 0 to content.getChildCount() - 1
        total = total + content.getChild(r).getChildCount()
    end for

    m.chanList.content = content
    if total > 0 then
        m.countLabel.text  = total.toStr() + " canales"
        m.emptyMsg.visible = false
        m.chanList.setFocus(true)
    else
        m.countLabel.text  = "Sin canales"
        m.emptyMsg.text    = "No hay canales disponibles." + chr(10) + "Intenta recargar desde Configuración."
        m.emptyMsg.visible = true
    end if
end sub

sub _onItemSelected()
    sel  = m.chanList.rowItemSelected
    ri   = sel[0]
    ii   = sel[1]
    content = m.top.channelData
    if content = invalid then return
    if ri < 0 or ri >= content.getChildCount() then return
    row = content.getChild(ri)
    if row = invalid or ii < 0 or ii >= row.getChildCount() then return
    item = row.getChild(ii)
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
        m.top.navigate = "sidebar"
        return true
    else if key = "options" then
        ri   = m.chanList.rowFocused
        ii   = m.chanList.rowItemFocused
        content = m.top.channelData
        if content <> invalid and ri >= 0 and ri < content.getChildCount() then
            row = content.getChild(ri)
            if row <> invalid and ii >= 0 and ii < row.getChildCount() then
                item = row.getChild(ii)
                if item <> invalid and item.hasField("chId") then
                    id = item.chId
                    if _isFav(id) then _removeFav(id) else _addFav(id)
                end if
            end if
        end if
        return true
    end if
    return false
end function
