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
    m.curName        = ""
    m.retryCount     = 0
    m.primaryUrl     = ""
    m.backupUrls     = []
    m.urlIndex       = 0
    m.lastBufPct     = -1
    m.stallCount     = 0

    m.video.observeField("state", "_onVideoState")

    m.zapTimer = createObject("roSGNode", "Timer")
    m.zapTimer.duration = 5
    m.zapTimer.repeat   = false
    m.zapTimer.observeField("fire", "_hideZap")

    m.errorTimer = createObject("roSGNode", "Timer")
    m.errorTimer.duration = 12
    m.errorTimer.repeat   = false
    m.errorTimer.observeField("fire", "_onErrorTimeout")

    ' Fires every 4 s while buffering — shows progress % and detects stalls
    m.stallTimer = createObject("roSGNode", "Timer")
    m.stallTimer.duration = 4
    m.stallTimer.repeat   = true
    m.stallTimer.observeField("fire", "_onStallCheck")

    m.clockTimer = createObject("roSGNode", "Timer")
    m.clockTimer.duration = 30
    m.clockTimer.repeat   = true
    m.clockTimer.observeField("fire", "_tick")
    m.clockTimer.control  = "start"
    _tick()
end sub

sub _onContent()
    c = m.top.content
    if c = invalid then return

    ' Remember the primary + backup URLs so we can fail over on error.
    m.primaryUrl = ""
    if c.hasField("url") and c.url <> invalid then m.primaryUrl = c.url
    m.backupUrls = []
    if c.hasField("backupUrls") and c.backupUrls <> invalid then m.backupUrls = c.backupUrls
    m.urlIndex   = 0
    m.retryCount = 0
    m.lastBufPct = -1
    m.stallCount = 0

    _playUrl(c, m.primaryUrl)

    if c.hasField("isLive") then m.isLive = c.isLive else m.isLive = (c.streamFormat = "hls")

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

    m.curName          = name
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

' Start playback of a specific URL on the current content node, attaching the
' HTTP headers that LATAM IPTV "panel" servers require. Roku's default video
' User-Agent (Roku/DVP-…) is frequently rejected by these panels — the stream
' hangs on "Cargando…" forever or returns 403. A VLC-style User-Agent, which
' these servers whitelist, lets the manifest and TS segments load. This is the
' single most common reason none of the channels played.
sub _playUrl(c as object, url as string)
    if url = "" then return
    c.url = url
    ' Roku ContentNode requires an roAssociativeArray for HttpHeaders — an array
    ' of strings is silently ignored by the Video node. LATAM panel servers
    ' (port 8000/29000/45000) block Roku's default UA; VLC UA is whitelisted.
    c.HttpHeaders = {
        "User-Agent": "VLC/3.0.20 LibVLC/3.0.20",
        "Connection": "keep-alive"
    }
    m.video.content = invalid
    m.video.content = c
    m.video.control = "play"
end sub

sub _onVideoState()
    st   = m.video.state
    name = ""
    if m.curName <> invalid then name = m.curName
    if st = "playing" then
        m.bufLabel.visible   = false
        m.errorTimer.control = "stop"
        m.stallTimer.control = "stop"
        m.retryCount         = 0
        m.lastBufPct         = -1
        m.stallCount         = 0
    else if st = "buffering" then
        pct = m.video.bufferPercentage
        m.bufLabel.text = "Cargando " + name + "…"
        if pct > 0 then m.bufLabel.text = m.bufLabel.text + " (" + pct.toStr() + "%)"
        m.bufLabel.visible   = true
        m.errorTimer.control = "stop"
        m.errorTimer.control = "start"
        m.stallTimer.control = "stop"
        m.stallTimer.control = "start"
        m.lastBufPct         = pct
        m.stallCount         = 0
    else if st = "error" then
        m.errorTimer.control = "stop"
        m.stallTimer.control = "stop"
        _onPlaybackFailed(name)
    else if st = "finished" then
        m.stallTimer.control = "stop"
        m.bufLabel.text    = "Transmisión finalizada." + chr(10) + "Pulsa ATRÁS para volver."
        m.bufLabel.visible = true
    end if
end sub

sub _onStallCheck()
    if m.video.state <> "buffering" then
        m.stallTimer.control = "stop"
        return
    end if
    ' Some HLS streams play audio while Roku still reports "buffering" state.
    ' If the playback position is advancing the stream IS playing — hide the
    ' loading overlay so the video is visible.
    pos = m.video.position
    if type(pos) = "Float" and pos > 0.5 then
        m.bufLabel.visible   = false
        m.stallTimer.control = "stop"
        return
    end if
    pct  = m.video.bufferPercentage
    name = ""
    if m.curName <> invalid then name = m.curName
    ' Update displayed percentage (only when field is available)
    m.bufLabel.text = "Cargando " + name + "…"
    if type(pct) = "Integer" and pct > 0 then
        m.bufLabel.text = m.bufLabel.text + " (" + pct.toStr() + "%)"
    end if
    ' Stall detection only works when bufferPercentage is supported by the device.
    ' On older firmware it returns invalid — skip stall logic entirely in that case
    ' to avoid false timeouts on streams that legitimately buffer slowly.
    if type(pct) = "Integer" then
        if pct = m.lastBufPct then
            m.stallCount = m.stallCount + 1
            if m.stallCount >= 2 then
                m.stallTimer.control = "stop"
                m.errorTimer.control = "stop"
                m.video.control      = "stop"
                _onPlaybackFailed(name)
                return
            end if
        else
            m.stallCount = 0
        end if
        m.lastBufPct = pct
    end if
end sub

' Failover ladder: try each backup URL, then one plain retry of the primary,
' before showing the "no disponible" message.
sub _onPlaybackFailed(name as string)
    c = m.top.content
    if c = invalid then return

    ' 1) Try the next backup URL, if any remain.
    if m.backupUrls <> invalid and m.urlIndex < m.backupUrls.count() then
        nextUrl = m.backupUrls[m.urlIndex]
        m.urlIndex = m.urlIndex + 1
        m.bufLabel.text    = "Buscando otra señal de " + name + "…"
        m.bufLabel.visible = true
        m.video.control    = "stop"
        _playUrl(c, nextUrl)
        return
    end if

    ' 2) One plain retry of the primary URL (transient network blips).
    if m.retryCount < 1 then
        m.retryCount = m.retryCount + 1
        m.bufLabel.text    = "Reintentando " + name + "…"
        m.bufLabel.visible = true
        m.video.control    = "stop"
        _playUrl(c, m.primaryUrl)
        return
    end if

    ' 3) Give up with a clear message.
    m.bufLabel.text    = "✕ No se pudo reproducir " + name + chr(10) + chr(10) + "Este canal puede estar fuera de línea o no disponible en tu región." + chr(10) + "Pulsa ATRÁS para volver y prueba otro."
    m.bufLabel.visible = true
end sub

sub _onErrorTimeout()
    ' Buffering too long — treat as a playback failure and run the failover ladder.
    name = ""
    if m.curName <> invalid then name = m.curName
    m.video.control = "stop"
    _onPlaybackFailed(name)
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
    m.video.control      = "stop"
    m.errorTimer.control = "stop"
    m.stallTimer.control = "stop"
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
