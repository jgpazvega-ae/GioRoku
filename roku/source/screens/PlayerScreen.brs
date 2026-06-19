sub init()
    m.video = m.top.findNode("video")
    m.infoOverlay = m.top.findNode("infoOverlay")
    m.progBar = m.top.findNode("progBar")
    m.controlsOverlay = m.top.findNode("controlsOverlay")
    m.optionsBg = m.top.findNode("optionsBg")
    m.optionsMenu = m.top.findNode("optionsMenu")
    m.bufferingLabel = m.top.findNode("bufferingLabel")

    m.overlayTimer = createObject("roSGNode", "Timer")
    m.overlayTimer.duration = 5
    m.overlayTimer.repeat = false
    m.overlayTimer.observeField("fire", "_hideOverlays")

    m.controlsVisible = false
    m.optionsVisible = false
    m.backupIndex = 0

    m.video.observeField("state", "_onVideoState")
    m.top.observeField("channel", "_onChannelSet")

    m.top.setFocus(true)
end sub

sub _onChannelSet()
    ch = m.top.channel
    if ch = invalid then return

    _updateInfoUI(ch)
    _startPlayback(ch.streamUrl)

    m.bufferingLabel.visible = true
    _showOverlays()
end sub

sub _startPlayback(url as String)
    content = createObject("roSGNode", "ContentNode")
    content.url = url
    content.title = m.top.channel.name
    content.streamFormat = "hls"
    content.live = true
    m.video.content = content
    m.video.control = "play"
end sub

sub _updateInfoUI(ch as Object)
    m.top.findNode("chLogo").uri = ch.logo
    m.top.findNode("chName").text = ch.name
    m.top.findNode("chCountry").text = ch.countryLabel + " - " + ch.categoryLabel

    prog = invalid
    if ch.DoesExist("currentProgram") then prog = ch.currentProgram
    if prog <> invalid then
        m.top.findNode("progTitle").text = prog.title
        nextProg = invalid
        if ch.DoesExist("nextProgram") then nextProg = ch.nextProgram
        if nextProg <> invalid then
            m.top.findNode("progNext").text = "A continuacion: " + nextProg.title
        else
            m.top.findNode("progNext").text = ""
        end if
    else
        m.top.findNode("progTitle").text = ch.name + " - En vivo"
        m.top.findNode("progNext").text = ""
    end if
end sub

sub _onVideoState()
    state = m.video.state
    if state = "playing" then
        m.bufferingLabel.visible = false
        m.backupIndex = 0
    else if state = "buffering" then
        m.bufferingLabel.visible = true
    else if state = "error" or state = "finished" then
        _tryBackup()
    end if
end sub

sub _tryBackup()
    ch = m.top.channel
    backups = []
    if ch.DoesExist("backupUrls") and ch.backupUrls <> invalid then
        backups = ch.backupUrls
    end if

    if m.backupIndex < backups.count() then
        url = backups[m.backupIndex]
        m.backupIndex = m.backupIndex + 1
        _startPlayback(url)
    else
        m.bufferingLabel.text = "Error de stream. Presiona OK para reintentar, Back para volver."
        m.bufferingLabel.visible = true
    end if
end sub

sub _showOverlays()
    m.infoOverlay.visible = true
    m.progBar.visible = true
    m.overlayTimer.control = "start"
end sub

sub _hideOverlays()
    if not m.controlsVisible and not m.optionsVisible then
        m.infoOverlay.visible = false
        m.progBar.visible = false
    end if
end sub

sub _toggleControls()
    m.controlsVisible = not m.controlsVisible
    m.controlsOverlay.visible = m.controlsVisible
    if m.controlsVisible then
        m.overlayTimer.control = "stop"
        _showOverlays()
    else
        m.overlayTimer.control = "start"
    end if
end sub

sub _showOptions()
    ch = m.top.channel
    favs = m.top.storage.getFavorites()
    isFav = false
    for each id in favs
        if id = ch.id then isFav = true
    end for

    labels = createObject("roSGNode", "ContentNode")
    l1 = labels.createChild("ContentNode")
    l1.title = iif(isFav, "Quitar de Favoritos", "Agregar a Favoritos")
    l2 = labels.createChild("ContentNode")
    l2.title = "Info del canal"
    l3 = labels.createChild("ContentNode")
    l3.title = "Cerrar"

    m.optionsMenu.content = labels
    m.optionsBg.visible = true
    m.optionsMenu.visible = true
    m.optionsVisible = true
    m.overlayTimer.control = "stop"
    _showOverlays()
end sub

sub _hideOptions()
    m.optionsBg.visible = false
    m.optionsMenu.visible = false
    m.optionsVisible = false
    m.overlayTimer.control = "start"
end sub

sub _channelUp()
    ch = m.top.channels.allChannels
    current = m.top.channel
    for i = 0 to ch.count() - 1
        if ch[i].id = current.id then
            nextIdx = (i + 1) mod ch.count()
            m.top.channel = ch[nextIdx]
            m.backupIndex = 0
            return
        end if
    end for
end sub

sub _channelDown()
    ch = m.top.channels.allChannels
    current = m.top.channel
    for i = 0 to ch.count() - 1
        if ch[i].id = current.id then
            prevIdx = i - 1
            if prevIdx < 0 then prevIdx = ch.count() - 1
            m.top.channel = ch[prevIdx]
            m.backupIndex = 0
            return
        end if
    end for
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if m.optionsVisible then
            if key = "OK" or key = "select" then
                idx = m.optionsMenu.itemFocused
                if idx = 0 then
                    ch = m.top.channel
                    favs = m.top.storage.getFavorites()
                    isFav = false
                    for each id in favs
                        if id = ch.id then isFav = true
                    end for
                    if isFav then
                        m.top.storage.removeFavorite(ch.id)
                    else
                        m.top.storage.addFavorite(ch.id)
                    end if
                end if
                _hideOptions()
                return true
            else if key = "back" then
                _hideOptions()
                return true
            end if
        else
            if key = "OK" or key = "select" then
                _toggleControls()
                return true
            else if key = "options" then
                _showOptions()
                return true
            else if key = "up" then
                _channelUp()
                return true
            else if key = "down" then
                _channelDown()
                return true
            else if key = "replay" or key = "instantreplay" then
                m.video.control = "stop"
                m.video.control = "play"
                return true
            else if key = "back" then
                m.video.control = "stop"
                m.overlayTimer.control = "stop"
                m.top.getScene().removeChild(m.top)
                return true
            end if
        end if
    end if
    return false
end sub
