' MainScene.brs — self-contained GioRoku scene: fetch, grid, playback.

function _baseUrl() as string
    return "https://jgpazvega-ae.github.io/GioRoku/api/v1"
end function

sub init()
    m.grid        = m.top.findNode("grid")
    m.status      = m.top.findNode("status")
    m.message     = m.top.findNode("message")
    m.video       = m.top.findNode("video")
    m.playbackMsg = m.top.findNode("playbackMsg")

    m.channels = []
    m.playing  = false

    m.grid.observeField("itemSelected", "_onItemSelected")
    m.video.observeField("state", "_onVideoState")

    m.grid.setFocus(true)

    ' Render one frame, then run the blocking network load.
    m.loadTimer = createObject("roSGNode", "Timer")
    m.loadTimer.duration = 0.4
    m.loadTimer.repeat = false
    m.loadTimer.observeField("fire", "_load")
    m.loadTimer.control = "start"
end sub

sub _load()
    m.status.text = "Conectando…"

    page = _getJSON("/channels/page/1.json")
    if page = invalid then
        _showMessage("Sin conexión a internet." + chr(10) + "Verifica tu red e inténtalo de nuevo.")
        m.status.text = "Sin conexión"
        return
    end if

    list = []
    if page.DoesExist("channels") and page.channels <> invalid then
        list = page.channels
    end if
    m.channels = list

    if list.count() = 0 then
        _showMessage("Aún no hay canales." + chr(10) + chr(10) + "Importa una lista M3U desde la herramienta web para llenar tu guía.")
        m.status.text = "0 canales"
        return
    end if

    _populateGrid(list)
    m.message.visible = false
    m.status.text = list.count().toStr() + " canales"
end sub

sub _populateGrid(list as object)
    content = createObject("roSGNode", "ContentNode")
    for each ch in list
        item = content.createChild("ContentNode")
        item.title = _str(ch, "name")
        item.hdPosterUrl = _str(ch, "logo")
        item.shortDescriptionLine1 = _str(ch, "countryLabel")
    end for
    m.grid.content = content
end sub

sub _onItemSelected()
    idx = m.grid.itemSelected
    if idx < 0 or idx >= m.channels.count() then return
    ch = m.channels[idx]
    url = _str(ch, "streamUrl")
    if url = "" then
        url = _str(ch, "url")
    end if
    if url = "" then return
    _play(url, _str(ch, "name"))
end sub

sub _play(url as string, name as string)
    content = createObject("roSGNode", "ContentNode")
    content.url = url
    content.title = name
    content.streamFormat = "hls"
    content.live = true

    m.video.content = content
    m.video.visible = true
    m.video.control = "play"
    m.playing = true

    m.playbackMsg.text = "Cargando " + name + "…"
    m.playbackMsg.visible = true
    m.video.setFocus(true)
end sub

sub _stop()
    m.video.control = "stop"
    m.video.visible = false
    m.playbackMsg.visible = false
    m.playing = false
    m.grid.setFocus(true)
end sub

sub _onVideoState()
    state = m.video.state
    if state = "playing" then
        m.playbackMsg.visible = false
    else if state = "buffering" then
        m.playbackMsg.text = "Cargando…"
        m.playbackMsg.visible = true
    else if state = "error" then
        m.playbackMsg.text = "No se pudo reproducir el canal." + chr(10) + "Presiona Atrás para volver."
        m.playbackMsg.visible = true
    end if
end sub

sub _showMessage(text as string)
    m.message.text = text
    m.message.visible = true
    m.grid.content = createObject("roSGNode", "ContentNode")
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.playing then
        if key = "back" then
            _stop()
            return true
        end if
    end if
    return false
end function

' ---- helpers ----

function _getJSON(path as string) as dynamic
    req = createObject("roUrlTransfer")
    req.setUrl(_baseUrl() + path)
    req.enableHostVerification(false)
    req.enablePeerVerification(false)
    req.addHeader("Accept", "application/json")
    req.addHeader("User-Agent", "GioRoku/1.0")
    resp = req.getToString()
    if resp = invalid or resp = "" then return invalid
    return parseJSON(resp)
end function

function _str(aa as object, key as string) as string
    if aa = invalid then return ""
    if not aa.DoesExist(key) then return ""
    v = aa[key]
    if v = invalid then return ""
    if type(v) = "String" or type(v) = "roString" then return v
    return v.toStr()
end function
