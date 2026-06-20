sub init()
    m.channelList = m.top.findNode("channelList")
    m.timeNowLabel = m.top.findNode("timeNowLabel")
    m.nowBar = m.top.findNode("nowBar")
    m.detailBg = m.top.findNode("detailBg")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailTime = m.top.findNode("detailTime")
    m.detailDesc = m.top.findNode("detailDesc")
    m.detailActions = m.top.findNode("detailActions")

    m.epgData = {}
    m.timeOffsetHours = 0
    m.detailVisible = false
    m.focusedChannelIdx = 0

    m.top.observeField("channels", "_onDataReady")
    m.channelList.observeField("itemFocused", "_onChannelFocused")

    _updateClock()
    m.clockTimer = createObject("roSGNode", "Timer")
    m.clockTimer.duration = 60
    m.clockTimer.repeat = true
    m.clockTimer.observeField("fire", "_updateClock")
    m.clockTimer.control = "start"

    m.channelList.setFocus(true)
end sub

sub _onDataReady()
    ch = m.top.channels
    if ch = invalid then return
    list = ch.allChannels

    content = createObject("roSGNode", "ContentNode")
    for each item in list
        node = content.createChild("ContentNode")
        node.id = item.id
        node.title = item.name
        node.hdPosterUrl = item.logo
        ' Attach program data for guide display
        if item.DoesExist("currentProgram") and item.currentProgram <> invalid then
            node.shortDescriptionLine1 = item.currentProgram.title
        else
            node.shortDescriptionLine1 = "Live TV"
        end if
    end for
    m.channelList.content = content

    _updateClock()
end sub

sub _updateClock()
    now = createObject("roDateTime")
    h = now.GetHours()
    mn = now.GetMinutes()
    ampm = "AM"
    if h >= 12 then
        ampm = "PM"
        if h > 12 then h = h - 12
    end if
    if h = 0 then h = 12
    mins = mn.toStr()
    if mn < 10 then mins = "0" + mins
    m.timeNowLabel.text = h.toStr() + ":" + mins + " " + ampm

    ' Position now bar (180px per 30 min = 360px/h)
    ' Offset from program area start (280px)
    currentMinutes = now.GetHours() * 60 + now.GetMinutes()
    baseMinutes = currentMinutes - (currentMinutes mod 30)
    pixelOffset = (currentMinutes - baseMinutes) * 6  ' 6px per min
    m.nowBar.translation = [280 + pixelOffset + m.timeOffsetHours * 360, 96]
end sub

sub _onChannelFocused()
    m.focusedChannelIdx = m.channelList.itemFocused
end sub

sub _showDetail(channelId as String)
    ch = m.top.channels.getChannel(channelId)
    if ch = invalid then return

    m.detailBg.visible = true
    m.detailTitle.visible = true
    m.detailTime.visible = true
    m.detailDesc.visible = true
    m.detailActions.visible = true

    prog = invalid
    if ch.DoesExist("currentProgram") then prog = ch.currentProgram

    if prog <> invalid then
        m.detailTitle.text = prog.title
        m.detailDesc.text = prog.description
        if prog.DoesExist("start") and prog.DoesExist("end") then
            m.detailTime.text = prog.start + " – " + prog.end
        end if
    else
        m.detailTitle.text = ch.name
        m.detailDesc.text = ch.categoryLabel + " · " + ch.countryLabel
        m.detailTime.text = "En vivo"
    end if

    m.detailVisible = true
end sub

sub _hideDetail()
    m.detailBg.visible = false
    m.detailTitle.visible = false
    m.detailTime.visible = false
    m.detailDesc.visible = false
    m.detailActions.visible = false
    m.detailVisible = false
end sub

sub _playFocusedChannel()
    item = m.channelList.content.getChild(m.focusedChannelIdx)
    if item = invalid then return
    ch = m.top.channels.getChannel(item.id)
    if ch = invalid then return

    m.top.storage.addRecentChannel(ch.id)
    player = createObject("roSGNode", "PlayerScreen")
    player.channel = ch
    player.channels = m.top.channels
    player.storage = m.top.storage
    m.top.getScene().appendChild(player)
    player.setFocus(true)
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if m.detailVisible then
            if key = "OK" or key = "select" then
                _hideDetail()
                _playFocusedChannel()
                return true
            else if key = "back" then
                _hideDetail()
                m.channelList.setFocus(true)
                return true
            end if
        else
            if key = "OK" or key = "select" then
                item = m.channelList.content.getChild(m.focusedChannelIdx)
                if item <> invalid then _showDetail(item.id)
                return true
            else if key = "left" or key = "rewind" then
                m.timeOffsetHours = m.timeOffsetHours - 1
                _updateClock()
                return true
            else if key = "right" or key = "fastforward" then
                m.timeOffsetHours = m.timeOffsetHours + 1
                _updateClock()
                return true
            else if key = "back" then
                m.clockTimer.control = "stop"
                m.top.getScene().removeChild(m.top)
                return true
            end if
        end if
    end if
    return false
end sub
