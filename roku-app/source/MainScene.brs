' MainScene.brs — GioRoku full single-scene app (nav + views + player).

function _baseUrl() as string
    return "https://jgpazvega-ae.github.io/GioRoku/api/v1"
end function

sub init()
    ' Node refs
    m.status   = m.top.findNode("status")
    m.message  = m.top.findNode("message")
    m.underline = m.top.findNode("navUnderline")

    m.tabsNodes = []
    for i = 0 to 5
        m.tabsNodes.push(m.top.findNode("tab" + i.toStr()))
    end for
    m.tabX = [340, 500, 660, 780, 980, 1140]
    m.tabW = [110, 120, 70, 150, 110, 120]

    m.views = {
        home:     m.top.findNode("viewHome"),
        live:     m.top.findNode("viewLive"),
        guide:    m.top.findNode("viewGuide"),
        fav:      m.top.findNode("viewFav"),
        search:   m.top.findNode("viewSearch"),
        settings: m.top.findNode("viewSettings")
    }

    m.homeGrid   = m.top.findNode("homeGrid")
    m.liveGrid   = m.top.findNode("liveGrid")
    m.favGrid    = m.top.findNode("favGrid")
    m.favEmpty   = m.top.findNode("favEmpty")
    m.guideList  = m.top.findNode("guideList")
    m.searchGrid = m.top.findNode("searchGrid")
    m.searchEmpty = m.top.findNode("searchEmpty")
    m.kbd        = m.top.findNode("kbd")
    m.settingsList = m.top.findNode("settingsList")
    m.settingsInfo = m.top.findNode("settingsInfo")
    m.liveFilter = m.top.findNode("liveFilter")

    ' Player nodes
    m.viewPlayer = m.top.findNode("viewPlayer")
    m.video      = m.top.findNode("video")
    m.playerMsg  = m.top.findNode("playerMsg")
    m.playerInfoBg = m.top.findNode("playerInfoBg")
    m.playerLogo = m.top.findNode("playerLogo")
    m.playerName = m.top.findNode("playerName")
    m.playerMeta = m.top.findNode("playerMeta")

    ' Context menu
    m.ctxBg   = m.top.findNode("ctxBg")
    m.ctxMenu = m.top.findNode("ctxMenu")

    ' State
    m.channels = []
    m.homeList = []
    m.liveList = []
    m.favList = []
    m.searchList = []
    m.tab = 0
    m.mode = "nav"
    m.searchFocus = "kbd"
    m.ctxChannel = invalid
    m.activeGrid = m.homeGrid
    m.countries = ["ALL", "MX", "AR", "CO", "CL", "PE", "UY", "VE", "EC", "BO"]
    m.countryIdx = 0

    ' Observers
    m.homeGrid.observeField("itemSelected", "_onHomeSelected")
    m.liveGrid.observeField("itemSelected", "_onLiveSelected")
    m.favGrid.observeField("itemSelected", "_onFavSelected")
    m.searchGrid.observeField("itemSelected", "_onSearchSelected")
    m.guideList.observeField("itemSelected", "_onGuideSelected")
    m.settingsList.observeField("itemFocused", "_onSettingsFocused")
    m.settingsList.observeField("itemSelected", "_onSettingsSelected")
    m.kbd.observeField("text", "_onSearchTextChange")
    m.video.observeField("state", "_onVideoState")

    _buildSettingsMenu()
    _highlightTab(0)
    m.top.setFocus(true)

    ' Defer the blocking network load until after first render.
    m.loadTimer = createObject("roSGNode", "Timer")
    m.loadTimer.duration = 0.4
    m.loadTimer.repeat = false
    m.loadTimer.observeField("fire", "_load")
    m.loadTimer.control = "start"
end sub

' ================= DATA LOAD =================

sub _load()
    m.status.text = "Conectando…"
    page = _getJSON("/channels/page/1.json")
    if page = invalid then
        _showMessage("Sin conexión a internet." + chr(10) + "Verifica tu red e inténtalo de nuevo.")
        m.status.text = "Sin conexión"
        return
    end if

    list = []
    if page.DoesExist("channels") and page.channels <> invalid then list = page.channels

    ' Load extra pages if present (capped to keep memory sane).
    totalPages = 1
    if page.DoesExist("totalPages") then totalPages = page.totalPages
    if totalPages > 1 then
        last = totalPages
        if last > 10 then last = 10
        for p = 2 to last
            extra = _getJSON("/channels/page/" + p.toStr() + ".json")
            if extra <> invalid and extra.DoesExist("channels") and extra.channels <> invalid then
                for each c in extra.channels
                    list.push(c)
                end for
            end if
        end for
    end if

    m.channels = list
    m.status.text = list.count().toStr() + " canales"

    if list.count() = 0 then
        m.message.text = "Aún no hay canales disponibles." + chr(10) + chr(10) + "Importa una lista M3U desde la herramienta web para llenar tu guía."
        m.message.visible = true
    else
        m.message.visible = false
    end if

    _populateHome()
    _populateLive()
    _populateGuide()
end sub

' ================= VIEW POPULATION =================

sub _populateHome()
    featured = []
    for each ch in m.channels
        if _bool(ch, "isFeatured") then featured.push(ch)
    end for
    if featured.count() = 0 then featured = m.channels
    m.homeList = featured
    m.homeGrid.content = _buildPosterContent(featured)
end sub

sub _populateLive()
    code = m.countries[m.countryIdx]
    if code = "ALL" then
        m.liveList = m.channels
        m.liveFilter.text = "Filtro: Todos   (pulsa * para cambiar país)"
    else
        filtered = []
        for each ch in m.channels
            if _str(ch, "country") = code then filtered.push(ch)
        end for
        m.liveList = filtered
        m.liveFilter.text = "Filtro: " + code + "   (pulsa * para cambiar país)"
    end if
    m.liveGrid.content = _buildPosterContent(m.liveList)
end sub

sub _populateGuide()
    content = createObject("roSGNode", "ContentNode")
    for each ch in m.channels
        item = content.createChild("ContentNode")
        meta = _str(ch, "countryLabel")
        cat = _str(ch, "categoryLabel")
        if cat <> "" then meta = meta + " · " + cat
        item.title = _str(ch, "name") + "    —    En vivo   " + meta
    end for
    m.guideList.content = content
end sub

sub _populateFav()
    favs = _getFavorites()
    m.favList = []
    for each id in favs
        ch = _findChannel(id)
        if ch <> invalid then m.favList.push(ch)
    end for
    if m.favList.count() = 0 then
        m.favGrid.content = createObject("roSGNode", "ContentNode")
        m.favEmpty.visible = true
    else
        m.favEmpty.visible = false
        m.favGrid.content = _buildPosterContent(m.favList)
    end if
end sub

function _buildPosterContent(list as object) as object
    content = createObject("roSGNode", "ContentNode")
    for each ch in list
        item = content.createChild("ContentNode")
        item.title = _str(ch, "name")
        item.shortDescriptionLine1 = _str(ch, "name")
        meta = _str(ch, "countryLabel")
        cat = _str(ch, "categoryLabel")
        if cat <> "" then
            if meta <> "" then meta = meta + " · "
            meta = meta + cat
        end if
        item.shortDescriptionLine2 = meta
        item.hdPosterUrl = _str(ch, "logo")
    end for
    return content
end function

' ================= NAV / VIEW SWITCHING =================

sub _highlightTab(i as integer)
    m.tab = i
    keys = ["home", "live", "guide", "fav", "search", "settings"]
    for k = 0 to 5
        if k = i then
            m.tabsNodes[k].color = "#FFFFFF"
            m.tabsNodes[k].font = "font:MediumBoldSystemFont"
        else
            m.tabsNodes[k].color = "#A0A0A0"
            m.tabsNodes[k].font = "font:MediumSystemFont"
        end if
    end for
    m.underline.translation = [m.tabX[i], 78]
    m.underline.width = m.tabW[i]

    for each name in keys
        m.views[name].visible = false
    end for
    m.views[keys[i]].visible = true

    ' Hide the global message unless Home with no channels.
    if i = 0 and m.channels.count() = 0 and m.message.text <> "" then
        m.message.visible = true
    else
        m.message.visible = false
    end if

    ' Refresh dynamic views on entry.
    if i = 3 then _populateFav()
end sub

sub _enterView()
    if m.tab = 0 then
        m.activeGrid = m.homeGrid
        m.mode = "view"
        m.homeGrid.setFocus(true)
    else if m.tab = 1 then
        m.activeGrid = m.liveGrid
        m.mode = "view"
        m.liveGrid.setFocus(true)
    else if m.tab = 2 then
        m.mode = "view"
        m.guideList.setFocus(true)
    else if m.tab = 3 then
        m.activeGrid = m.favGrid
        m.mode = "view"
        m.favGrid.setFocus(true)
    else if m.tab = 4 then
        m.mode = "search"
        m.searchFocus = "kbd"
        m.kbd.setFocus(true)
    else if m.tab = 5 then
        m.mode = "view"
        m.settingsList.setFocus(true)
    end if
end sub

sub _backToNav()
    m.mode = "nav"
    m.top.setFocus(true)
end sub

' ================= SELECTION HANDLERS =================

sub _onHomeSelected()
    _chooseFromList(m.homeList, m.homeGrid.itemSelected)
end sub
sub _onLiveSelected()
    _chooseFromList(m.liveList, m.liveGrid.itemSelected)
end sub
sub _onFavSelected()
    _chooseFromList(m.favList, m.favGrid.itemSelected)
end sub
sub _onSearchSelected()
    _chooseFromList(m.searchList, m.searchGrid.itemSelected)
end sub
sub _onGuideSelected()
    _chooseFromList(m.channels, m.guideList.itemSelected)
end sub

sub _chooseFromList(list as object, idx as integer)
    if idx < 0 or idx >= list.count() then return
    _play(list[idx])
end sub

' ================= PLAYER =================

sub _play(ch as object)
    url = _str(ch, "streamUrl")
    if url = "" then url = _str(ch, "url")
    if url = "" then return

    m.currentChannel = ch
    content = createObject("roSGNode", "ContentNode")
    content.url = url
    content.title = _str(ch, "name")
    content.streamFormat = "hls"
    content.live = true
    m.video.content = content
    m.video.visible = true
    m.video.control = "play"

    m.playerName.text = _str(ch, "name")
    meta = _str(ch, "countryLabel")
    cat = _str(ch, "categoryLabel")
    if cat <> "" then meta = meta + " · " + cat
    m.playerMeta.text = meta
    logo = _str(ch, "logo")
    m.playerLogo.uri = logo
    m.playerInfoBg.visible = true
    m.playerLogo.visible = (logo <> "")
    m.playerName.visible = true
    m.playerMeta.visible = true
    m.playerMsg.text = "Cargando " + _str(ch, "name") + "…"
    m.playerMsg.visible = true

    m.viewPlayer.visible = true
    m.mode = "player"
    _addRecent(_str(ch, "id"))
    m.top.setFocus(true)
end sub

sub _stopPlayer()
    m.video.control = "stop"
    m.video.visible = false
    m.viewPlayer.visible = false
    m.playerMsg.visible = false
    m.mode = "view"
    if m.activeGrid <> invalid then
        m.activeGrid.setFocus(true)
    else
        m.top.setFocus(true)
        m.mode = "nav"
    end if
end sub

sub _onVideoState()
    st = m.video.state
    if st = "playing" then
        m.playerMsg.visible = false
    else if st = "buffering" then
        m.playerMsg.text = "Cargando…"
        m.playerMsg.visible = true
    else if st = "error" then
        m.playerMsg.text = "No se pudo reproducir el canal." + chr(10) + "Presiona Atrás para volver."
        m.playerMsg.visible = true
    end if
end sub

sub _channelStep(delta as integer)
    if m.currentChannel = invalid or m.channels.count() = 0 then return
    curId = _str(m.currentChannel, "id")
    for i = 0 to m.channels.count() - 1
        if _str(m.channels[i], "id") = curId then
            n = i + delta
            if n < 0 then n = m.channels.count() - 1
            if n >= m.channels.count() then n = 0
            _play(m.channels[n])
            return
        end if
    end for
end sub

' ================= CONTEXT MENU =================

sub _openContext(ch as object)
    if ch = invalid then return
    m.ctxChannel = ch
    isFav = _isFav(_str(ch, "id"))
    content = createObject("roSGNode", "ContentNode")
    a = content.createChild("ContentNode")
    a.title = iif(isFav, "Quitar de Favoritos", "Agregar a Favoritos")
    b = content.createChild("ContentNode")
    b.title = "Reproducir"
    c = content.createChild("ContentNode")
    c.title = "Cerrar"
    m.ctxMenu.content = content
    m.ctxBg.visible = true
    m.ctxMenu.visible = true
    m.ctxMenu.jumpToItem = 0
    m.prevMode = m.mode
    m.mode = "ctx"
    m.ctxMenu.setFocus(true)
end sub

sub _closeContext()
    m.ctxBg.visible = false
    m.ctxMenu.visible = false
    m.mode = "view"
    if m.activeGrid <> invalid then m.activeGrid.setFocus(true)
end sub

sub _ctxActivate()
    idx = m.ctxMenu.itemFocused
    ch = m.ctxChannel
    if idx = 0 then
        id = _str(ch, "id")
        if _isFav(id) then
            _removeFav(id)
        else
            _addFav(id)
        end if
        if m.tab = 3 then _populateFav()
    else if idx = 1 then
        _closeContext()
        _play(ch)
        return
    end if
    _closeContext()
end sub

' ================= SEARCH =================

sub _onSearchTextChange()
    q = m.kbd.text
    if q = invalid then q = ""
    q = lcase(q.trim())
    if q = "" then
        m.searchList = []
        m.searchGrid.content = createObject("roSGNode", "ContentNode")
        m.searchEmpty.visible = false
        return
    end if
    results = []
    for each ch in m.channels
        hay = lcase(_str(ch, "name") + " " + _str(ch, "categoryLabel") + " " + _str(ch, "countryLabel"))
        if instr(1, hay, q) > 0 then results.push(ch)
        if results.count() >= 100 then exit for
    end for
    m.searchList = results
    if results.count() = 0 then
        m.searchGrid.content = createObject("roSGNode", "ContentNode")
        m.searchEmpty.text = "Sin resultados para """ + q + """"
        m.searchEmpty.visible = true
    else
        m.searchEmpty.visible = false
        m.searchGrid.content = _buildPosterContent(results)
    end if
end sub

' ================= SETTINGS =================

sub _buildSettingsMenu()
    content = createObject("roSGNode", "ContentNode")
    titles = ["Tema", "País preferido", "Controles parentales", "Limpiar datos guardados", "Acerca de GioRoku"]
    for each t in titles
        n = content.createChild("ContentNode")
        n.title = t
    end for
    m.settingsList.content = content
    m.settingsInfo.text = "Selecciona una opción a la izquierda."
end sub

sub _onSettingsFocused()
    idx = m.settingsList.itemFocused
    s = _getSettings()
    if idx = 0 then
        m.settingsInfo.text = "Tema: Oscuro" + chr(10) + chr(10) + "GioRoku usa un tema oscuro optimizado para televisores."
    else if idx = 1 then
        m.settingsInfo.text = "País preferido: " + s.countryPref + chr(10) + chr(10) + "Pulsa OK para cambiar el país que se prioriza en Live TV."
    else if idx = 2 then
        st = "Desactivado"
        if s.parentalEnabled then st = "Activado"
        m.settingsInfo.text = "Controles parentales: " + st + chr(10) + chr(10) + "Pulsa OK para activar o desactivar."
    else if idx = 3 then
        m.settingsInfo.text = "Limpiar datos guardados" + chr(10) + chr(10) + "Pulsa OK para borrar favoritos y canales recientes."
    else if idx = 4 then
        m.settingsInfo.text = "GioRoku v1.0" + chr(10) + "Tu televisión latina en Roku." + chr(10) + chr(10) + "Datos: GitHub Pages API" + chr(10) + "Los streams provienen de fuentes públicas de terceros."
    end if
end sub

sub _onSettingsSelected()
    idx = m.settingsList.itemSelected
    s = _getSettings()
    if idx = 1 then
        m.countryIdx = (m.countryIdx + 1) mod m.countries.count()
        _setSetting("countryPref", m.countries[m.countryIdx])
        _populateLive()
    else if idx = 2 then
        _setSetting("parentalEnabled", not s.parentalEnabled)
    else if idx = 3 then
        _regWrite("favorites", "[]")
        _regWrite("recentChannels", "[]")
        m.settingsInfo.text = "Datos borrados." + chr(10) + "Favoritos y recientes se han limpiado."
        return
    end if
    _onSettingsFocused()
end sub

' ================= KEY HANDLING =================

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.mode = "player" then
        if key = "back" then
            _stopPlayer()
            return true
        else if key = "up" then
            _channelStep(1)
            return true
        else if key = "down" then
            _channelStep(-1)
            return true
        else if key = "options" then
            _openContext(m.currentChannel)
            return true
        end if
        return true
    end if

    if m.mode = "ctx" then
        if key = "OK" then
            _ctxActivate()
            return true
        else if key = "back" then
            _closeContext()
            return true
        end if
        return false
    end if

    if m.mode = "nav" then
        if key = "left" then
            if m.tab > 0 then _highlightTab(m.tab - 1)
            return true
        else if key = "right" then
            if m.tab < 5 then _highlightTab(m.tab + 1)
            return true
        else if key = "OK" or key = "down" then
            _enterView()
            return true
        end if
        return false
    end if

    if m.mode = "search" then
        if key = "back" then
            if m.searchFocus = "kbd" and m.searchList.count() > 0 then
                m.searchFocus = "grid"
                m.searchGrid.setFocus(true)
                return true
            else
                _backToNav()
                return true
            end if
        else if key = "up" and m.searchFocus = "grid" then
            m.searchFocus = "kbd"
            m.kbd.setFocus(true)
            return true
        end if
        return false
    end if

    ' mode = "view"
    if key = "back" then
        _backToNav()
        return true
    else if key = "options" then
        _openContextForActiveGrid()
        return true
    end if
    return false
end function

sub _openContextForActiveGrid()
    list = invalid
    grid = invalid
    if m.tab = 0 then
        list = m.homeList : grid = m.homeGrid
    else if m.tab = 1 then
        list = m.liveList : grid = m.liveGrid
    else if m.tab = 3 then
        list = m.favList : grid = m.favGrid
    else if m.tab = 2 then
        idx = m.guideList.itemFocused
        if idx >= 0 and idx < m.channels.count() then _openContext(m.channels[idx])
        return
    end if
    if grid <> invalid and list <> invalid then
        idx = grid.itemFocused
        if idx >= 0 and idx < list.count() then _openContext(list[idx])
    end if
end sub

' ================= STORAGE (registry) =================

function _regRead(key as string) as dynamic
    reg = createObject("roRegistrySection", "GioRoku")
    if reg.exists(key) then return reg.read(key)
    return invalid
end function

sub _regWrite(key as string, value as string)
    reg = createObject("roRegistrySection", "GioRoku")
    reg.write(key, value)
    reg.flush()
end sub

function _getFavorites() as object
    raw = _regRead("favorites")
    if raw = invalid or raw = "" then return []
    parsed = parseJSON(raw)
    if type(parsed) <> "roArray" then return []
    return parsed
end function

function _isFav(id as string) as boolean
    for each f in _getFavorites()
        if f = id then return true
    end for
    return false
end function

sub _addFav(id as string)
    favs = _getFavorites()
    for each f in favs
        if f = id then return
    end for
    favs.push(id)
    _regWrite("favorites", formatJSON(favs))
end sub

sub _removeFav(id as string)
    out = []
    for each f in _getFavorites()
        if f <> id then out.push(f)
    end for
    _regWrite("favorites", formatJSON(out))
end sub

sub _addRecent(id as string)
    raw = _regRead("recentChannels")
    arr = []
    if raw <> invalid and raw <> "" then
        p = parseJSON(raw)
        if type(p) = "roArray" then arr = p
    end if
    out = [id]
    for each r in arr
        if r <> id and out.count() < 20 then out.push(r)
    end for
    _regWrite("recentChannels", formatJSON(out))
end sub

function _getSettings() as object
    raw = _regRead("settings")
    defaults = { countryPref: "ALL", parentalEnabled: false }
    if raw = invalid or raw = "" then return defaults
    p = parseJSON(raw)
    if type(p) <> "roAssociativeArray" then return defaults
    for each k in defaults
        if p[k] = invalid then p[k] = defaults[k]
    end for
    return p
end function

sub _setSetting(key as string, value as dynamic)
    s = _getSettings()
    s[key] = value
    _regWrite("settings", formatJSON(s))
end sub

' ================= HELPERS =================

sub _showMessage(text as string)
    m.message.text = text
    m.message.visible = true
end sub

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

function _findChannel(id as string) as dynamic
    for each ch in m.channels
        if _str(ch, "id") = id then return ch
    end for
    return invalid
end function

function _str(aa as object, key as string) as string
    if aa = invalid then return ""
    if type(aa) <> "roAssociativeArray" then return ""
    if not aa.DoesExist(key) then return ""
    v = aa[key]
    if v = invalid then return ""
    if type(v) = "String" or type(v) = "roString" then return v
    return v.toStr()
end function

function _bool(aa as object, key as string) as boolean
    if aa = invalid then return false
    if type(aa) <> "roAssociativeArray" then return false
    if not aa.DoesExist(key) then return false
    return (aa[key] = true)
end function

function iif(cond as boolean, a as dynamic, b as dynamic) as dynamic
    if cond then return a
    return b
end function
