sub init()
    m.video     = m.top.findNode("video")
    m.bufLabel  = m.top.findNode("bufLabel")

    ' Zap banner nodes
    m.zapBg     = m.top.findNode("zapBg")
    m.zapNumBg  = m.top.findNode("zapNumBg")
    m.zapNum    = m.top.findNode("zapNum")
    m.zapLogo   = m.top.findNode("zapLogo")
    m.zapName   = m.top.findNode("zapName")
    m.zapMeta   = m.top.findNode("zapMeta")
    m.zapClock  = m.top.findNode("zapClock")
    m.zapHint   = m.top.findNode("zapHint")

    ' Info overlay nodes
    m.infoBg    = m.top.findNode("infoBg")
    m.infoLogo  = m.top.findNode("infoLogo")
    m.infoTitle = m.top.findNode("infoTitle")
    m.infoMeta  = m.top.findNode("infoMeta")
    m.infoBadge = m.top.findNode("infoBadge")
    m.progBg    = m.top.findNode("progBg")
    m.progBar   = m.top.findNode("progBar")
    m.progTime  = m.top.findNode("progTime")

    m.overlayVisible = false
    m.isLive         = true

    m.video.observeField("state", "_onVideoState")

    m.zapTimer = createObject("roSGNode", "Timer")
    m.zapTimer.duration = 5
    m.zapTimer.repeat   = false
    m.zapTimer.observeField("fire", "_hideZap")

    m.clockTimer = createObject("roSGNode", "Timer")
    m.clockTimer.duration = 1
    m.clockTimer.repeat   = true
    m.clockTimer.observeField("fire", "_tick")
    m.clockTimer.control  = "start"
    _tick()
end sub

sub _onContent()
    c = m.top.content
    if c = invalid then return

    m.video.content = c
    m.video.control = "play"

    m.isLive = (c.streamFormat = "hls")

    ' Fill zap banner
    num  = ""
    logo = ""
    name = ""
    meta = ""
    if c.hasField("chNum") and c.chNum <> invalid then num = c.chNum
    logo = c.hdPosterUrl
    name = c.title
    if c.hasField("isLive") and c.isLive then
        m.zapHint.text = "▲▼ Canal    OK Info    Atrás Salir"
    else
        m.zapHint.text = "OK Info    Atrás Salir"
    end if

    if num <> "" then
        m.zapNum.text      = num
        m.zapNumBg.visible = true
        m.zapNum.visible   = true
        m.zapLogo.translation = [200, 30]
        m.zapName.translation = [380, 30]
        m.zapMeta.translation = [380, 80]
    else
        m.zapNumBg.visible = false
        m.zapNum.visible   = false
        m.zapLogo.translation = [40, 30]
        m.zapName.translation = [220, 30]
        m.zapMeta.translation = [220, 80]
    end if
    if logo <> "" then
        m.zapLogo.uri     = logo
        m.zapLogo.visible = true
    else
        m.zapLogo.visible = false
    end if
    m.zapName.text = name

    m.bufLabel.text    = "Cargando " + name + "…"
    m.bufLabel.visible = true

    ' Track for recent
    if c.hasField("chId") and c.chId <> "" then
        _addRecent(c.chId)
    end if

    ' Info overlay prefill
    m.infoTitle.text = name
    m.infoMeta.text  = meta
    m.infoLogo.uri   = logo
    if m.isLive then
        m.infoBadge.text  = "● EN VIVO"
        m.infoBadge.color = "#CC1F1F"
    else
        m.infoBadge.text  = "Película"
        m.infoBadge.color = "#9CA3AF"
    end if

    _showZap()
end sub

sub _onVideoState()
    st = m.video.state
    if st = "playing" then
        m.bufLabel.visible = false
    else if st = "buffering" then
        m.bufLabel.text    = "Cargando…"
        m.bufLabel.visible = true
    else if st = "error" then
        m.bufLabel.text    = "No se pudo reproducir." + chr(10) + "Presiona Atrás para volver."
        m.bufLabel.visible = true
    end if
end sub

sub _showZap()
    m.zapBg.visible   = true
    m.zapName.visible = true
    m.zapMeta.visible = true
    m.zapClock.visible = true
    m.zapHint.visible  = true
    m.zapTimer.control = "stop"
    m.zapTimer.control = "start"
end sub

sub _hideZap()
    m.zapBg.visible    = false
    m.zapNumBg.visible = false
    m.zapNum.visible   = false
    m.zapLogo.visible  = false
    m.zapName.visible  = false
    m.zapMeta.visible  = false
    m.zapClock.visible = false
    m.zapHint.visible  = false
    m.zapTimer.control = "stop"
end sub

sub _showInfo()
    m.overlayVisible = true
    m.infoBg.visible    = true
    m.infoLogo.visible  = true
    m.infoTitle.visible = true
    m.infoMeta.visible  = true
    m.infoBadge.visible = true
    m.progBg.visible    = true
    m.progBar.visible   = true
    m.progTime.visible  = true
    if not m.isLive then
        elapsed = m.video.position
        dur = m.video.duration
        if dur > 0 then
            pct = int((elapsed / dur) * 1520)
            m.progBar.width = pct
            mins = int(elapsed / 60)
            secs = int(elapsed mod 60)
            ss   = secs.toStr()
            if len(ss) < 2 then ss = "0" + ss
            totM = int(dur / 60)
            totS = int(dur mod 60)
            totSS = totS.toStr()
            if len(totSS) < 2 then totSS = "0" + totSS
            m.progTime.text = mins.toStr() + ":" + ss + " / " + totM.toStr() + ":" + totSS
        end if
    else
        m.progBar.width = 1520
        m.progTime.text = "EN VIVO"
    end if
end sub

sub _hideInfo()
    m.overlayVisible = false
    m.infoBg.visible    = false
    m.infoLogo.visible  = false
    m.infoTitle.visible = false
    m.infoMeta.visible  = false
    m.infoBadge.visible = false
    m.progBg.visible    = false
    m.progBar.visible   = false
    m.progTime.visible  = false
end sub

sub _channelStep(delta as integer)
    allCh = m.top.allChannels
    if allCh = invalid then return
    total = allCh.getChildCount()
    if total = 0 then return

    cur   = m.top.content
    curId = ""
    if cur <> invalid and cur.hasField("chId") then curId = cur.chId

    curIdx = 0
    for i = 0 to total - 1
        ch = allCh.getChild(i)
        chId = ""
        if ch.hasField("chId") then chId = ch.chId
        if chId = curId then curIdx = i : exit for
    end for

    nextIdx = (curIdx + delta + total) mod total
    m.top.content = allCh.getChild(nextIdx)
end sub

sub _tick()
    m.zapClock.text = _clockStr()
end sub

sub _stopPlayer()
    m.video.control = "stop"
    _hideZap()
    _hideInfo()
    m.top.done = true
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back" then
        _stopPlayer()
        return true
    else if key = "OK" then
        if m.overlayVisible then
            _hideInfo()
        else
            _hideZap()
            _showInfo()
        end if
        return true
    else if key = "up" then
        if m.isLive then _channelStep(1)
        return true
    else if key = "down" then
        if m.isLive then _channelStep(-1)
        return true
    else if key = "options" then
        c = m.top.content
        if c <> invalid and c.hasField("chId") then
            id = c.chId
            if _isFav(id) then
                _removeFav(id)
            else
                _addFav(id)
            end if
        end if
        return true
    end if
    return false
end function
