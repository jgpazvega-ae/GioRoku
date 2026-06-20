' MainScene.brs — GioRoku single-scene app.

function _baseUrl() as string
    return "https://jgpazvega-ae.github.io/GioRoku/api/v1"
end function

' ================= INIT =================

sub init()
    m.status    = m.top.findNode("status")
    m.message   = m.top.findNode("message")
    m.underline = m.top.findNode("navUnderline")

    m.tabsNodes = []
    for i = 0 to 5
        m.tabsNodes.push(m.top.findNode("tab" + i.toStr()))
    end for
    m.tabX = [248, 422, 630, 734, 950, 1074]
    m.tabW = [120, 162, 58, 140, 90, 110]

    m.views = {
        home:     m.top.findNode("viewHome"),
        live:     m.top.findNode("viewLive"),
        guide:    m.top.findNode("viewGuide"),
        fav:      m.top.findNode("viewFav"),
        search:   m.top.findNode("viewSearch"),
        settings: m.top.findNode("viewSettings")
    }

    ' Grid / list widgets
    m.homeGrid    = m.top.findNode("homeGrid")
    m.catGrid     = m.top.findNode("catGrid")
    m.favGrid     = m.top.findNode("favGrid")
    m.favEmpty    = m.top.findNode("favEmpty")
    m.guideList   = m.top.findNode("guideList")
    m.searchGrid  = m.top.findNode("searchGrid")
    m.searchEmpty = m.top.findNode("searchEmpty")
    m.kbd         = m.top.findNode("kbd")
    m.settingsList  = m.top.findNode("settingsList")
    m.settingsInfo  = m.top.findNode("settingsInfo")

    ' Info panel (right side, shown for tabs 0-2)
    m.infoPanel  = m.top.findNode("infoPanel")
    m.infoName   = m.top.findNode("infoName")
    m.infoMeta   = m.top.findNode("infoMeta")
    m.infoLogo   = m.top.findNode("infoLogo")
    m.infoBadge  = m.top.findNode("infoBadge")

    ' Player
    m.viewPlayer   = m.top.findNode("viewPlayer")
    m.video        = m.top.findNode("video")
    m.playerMsg    = m.top.findNode("playerMsg")
    m.playerInfoBg = m.top.findNode("playerInfoBg")
    m.playerLogo   = m.top.findNode("playerLogo")
    m.playerName   = m.top.findNode("playerName")
    m.playerMeta   = m.top.findNode("playerMeta")

    ' Context menu
    m.ctxBg   = m.top.findNode("ctxBg")
    m.ctxMenu = m.top.findNode("ctxMenu")

    ' State
    m.channels       = []
    m.homeFlat       = []
    m.catFlat        = []
    m.favList        = []
    m.searchList     = []
    m.tab            = 0
    m.mode           = "nav"
    m.searchFocus    = "kbd"
    m.ctxChannel     = invalid
    m.activeGrid     = m.homeGrid
    m.activeFlatList = m.homeFlat
    m.currentChannel = invalid

    ' Observers
    m.homeGrid.observeField("itemSelected",   "_onHomeSelected")
    m.homeGrid.observeField("itemFocused",    "_onHomeFocused")
    m.catGrid.observeField("itemSelected",    "_onCatSelected")
    m.catGrid.observeField("itemFocused",     "_onCatFocused")
    m.favGrid.observeField("itemSelected",    "_onFavSelected")
    m.searchGrid.observeField("itemSelected", "_onSearchSelected")
    m.guideList.observeField("itemSelected",  "_onGuideSelected")
    m.guideList.observeField("itemFocused",   "_onGuideFocused")
    m.settingsList.observeField("itemFocused",  "_onSettingsFocused")
    m.settingsList.observeField("itemSelected", "_onSettingsSelected")
    m.kbd.observeField("text",   "_onSearchTextChange")
    m.video.observeField("state","_onVideoState")

    _buildSettingsMenu()
    _highlightTab(0)
    m.top.setFocus(true)

    m.loadTimer = createObject("roSGNode", "Timer")
    m.loadTimer.duration = 0.3
    m.loadTimer.repeat   = false
    m.loadTimer.observeField("fire", "_load")
    m.loadTimer.control  = "start"
end sub

' ================= DATA LOAD =================

sub _load()
    m.status.text     = "Conectando…"
    m.message.visible = false
    m.loadTask = createObject("roSGNode", "LoadTask")
    m.loadTask.baseUrl = _baseUrl()
    m.loadTask.observeField("taskState", "_onLoadState")
    m.loadTask.control = "RUN"
end sub

sub _onLoadState()
    if m.loadTask = invalid then return
    state = m.loadTask.taskState
    if state = "error" then
        _showMessage("Sin conexión a internet." + chr(10) + "Verifica tu red e inténtalo de nuevo.")
        m.status.text = "Sin conexión"
    else if state = "done" then
        res  = m.loadTask.result
        list = []
        if res <> invalid and res.DoesExist("channels") and res.channels <> invalid then
            list = res.channels
        end if
        m.channels    = list
        m.status.text = list.count().toStr() + " canales"
        if list.count() = 0 then
            m.message.text = "Aún no hay canales." + chr(10) + chr(10) + "Importa una lista M3U desde la herramienta web."
            m.message.visible = true
        else
            m.message.visible = false
        end if
        _populateHome()
        _populateCat()
        _populateGuide()
        _highlightTab(m.tab)
    end if
end sub

' ================= VIEW POPULATION =================

' CANALES: flat grid, México first, then remaining countries in order.
sub _populateHome()
    m.homeFlat = []
    content = createObject("roSGNode", "ContentNode")
    order   = ["MX","AR","CO","CL","PE","UY","VE","EC","BO","CA","US_ES","INTL"]
    grouped = {}
    for each ch in m.channels
        code = _str(ch, "country")
        if code = "" then code = "INTL"
        if not grouped.DoesExist(code) then grouped[code] = []
        grouped[code].push(ch)
    end for
    for each code in order
        if grouped.DoesExist(code) then
            for each ch in grouped[code]
                item = content.createChild("ContentNode")
                item.title = _str(ch, "name")
                item.shortDescriptionLine1 = _str(ch, "countryLabel")
                item.hdPosterUrl = _str(ch, "logo")
                m.homeFlat.push(ch)
            end for
        end if
    end for
    m.homeGrid.content = content
    if m.homeFlat.count() > 0 then _updateInfoPanel(m.homeFlat[0])
end sub

' CATEGORÍAS: flat grid organized by category.
sub _populateCat()
    m.catFlat = []
    content = createObject("roSGNode", "ContentNode")
    order   = ["entertainment","news","sports","movies","kids","music","documentary","religious","shopping"]
    grouped = {}
    for each ch in m.channels
        cat = _str(ch, "category")
        if cat = "" then cat = "entertainment"
        if not grouped.DoesExist(cat) then grouped[cat] = []
        grouped[cat].push(ch)
    end for
    for each cat in order
        if grouped.DoesExist(cat) then
            for each ch in grouped[cat]
                item = content.createChild("ContentNode")
                item.title = _str(ch, "name")
                item.shortDescriptionLine1 = _str(ch, "categoryLabel")
                item.hdPosterUrl = _str(ch, "logo")
                m.catFlat.push(ch)
            end for
        end if
    end for
    m.catGrid.content = content
    if m.catFlat.count() > 0 then _updateInfoPanel(m.catFlat[0])
end sub

sub _populateGuide()
    content = createObject("roSGNode", "ContentNode")
    for each ch in m.channels
        item = content.createChild("ContentNode")
        meta = _str(ch, "countryLabel")
        cat  = _str(ch, "categoryLabel")
        if cat <> "" then meta = meta + " · " + cat
        item.title = _str(ch, "name") + "    —    " + meta
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
        content = createObject("roSGNode", "ContentNode")
        for each ch in m.favList
            item = content.createChild("ContentNode")
            item.title = _str(ch, "name")
            item.shortDescriptionLine1 = _str(ch, "countryLabel")
            item.hdPosterUrl = _str(ch, "logo")
        end for
        m.favGrid.content = content
    end if
end sub

' ================= INFO PANEL =================

' Updates the right-side info panel with channel details.
sub _updateInfoPanel(ch as object)
    if ch = invalid then
        m.infoName.text = "Selecciona un canal"
        m.infoMeta.text = ""
        m.infoLogo.uri  = ""
        return
    end if
    m.infoName.text = _str(ch, "name")
    country = _str(ch, "countryLabel")
    cat     = _str(ch, "categoryLabel")
    if country <> "" and cat <> "" then
        m.infoMeta.text = country + " · " + cat
    else
        m.infoMeta.text = country + cat
    end if
    m.infoLogo.uri = _str(ch, "logo")
end sub

sub _onHomeFocused()
    idx = m.homeGrid.itemFocused
    if idx >= 0 and idx < m.homeFlat.count() then
        _updateInfoPanel(m.homeFlat[idx])
    end if
end sub

sub _onCatFocused()
    idx = m.catGrid.itemFocused
    if idx >= 0 and idx < m.catFlat.count() then
        _updateInfoPanel(m.catFlat[idx])
    end if
end sub

sub _onGuideFocused()
    idx = m.guideList.itemFocused
    if idx >= 0 and idx < m.channels.count() then
        _updateInfoPanel(m.channels[idx])
    end if
end sub

' ================= NAV / VIEW SWITCHING =================

sub _highlightTab(i as integer)
    m.tab = i
    for k = 0 to 5
        if k = i then
            m.tabsNodes[k].color = "#FFFFFF"
            m.tabsNodes[k].font  = "font:MediumBoldSystemFont"
        else
            m.tabsNodes[k].color = "#787878"
            m.tabsNodes[k].font  = "font:MediumSystemFont"
        end if
    end for
    m.underline.translation = [m.tabX[i], 108]
    m.underline.width       = m.tabW[i]

    keys = ["home","live","guide","fav","search","settings"]
    for each name in keys
        m.views[name].visible = false
    end for
    m.views[keys[i]].visible = true

    ' Info panel: show for CANALES, CATEGORÍAS, GUÍA; hide for the rest.
    m.infoPanel.visible = (i = 0 or i = 1 or i = 2)

    if i = 0 and m.channels.count() = 0 and m.message.text <> "" then
        m.message.visible = true
    else
        m.message.visible = false
    end if

    if i = 3 then _populateFav()
end sub

sub _enterView()
    if m.tab = 0 then
        m.activeGrid     = m.homeGrid
        m.activeFlatList = m.homeFlat
        m.mode           = "view"
        m.homeGrid.setFocus(true)
    else if m.tab = 1 then
        m.activeGrid     = m.catGrid
        m.activeFlatList = m.catFlat
        m.mode           = "view"
        m.catGrid.setFocus(true)
    else if m.tab = 2 then
        m.activeGrid     = invalid
        m.activeFlatList = invalid
        m.mode           = "view"
        m.guideList.setFocus(true)
    else if m.tab = 3 then
        m.activeGrid     = m.favGrid
        m.activeFlatList = m.favList
        m.mode           = "view"
        m.favGrid.setFocus(true)
    else if m.tab = 4 then
        m.mode        = "search"
        m.searchFocus = "kbd"
        m.kbd.setFocus(true)
    else if m.tab = 5 then
        m.activeGrid     = invalid
        m.activeFlatList = invalid
        m.mode           = "view"
        m.settingsList.setFocus(true)
    end if
end sub

sub _backToNav()
    m.mode = "nav"
    m.top.setFocus(true)
end sub

' ================= SELECTION HANDLERS =================

sub _onHomeSelected()
    idx = m.homeGrid.itemSelected
    if idx >= 0 and idx < m.homeFlat.count() then _play(m.homeFlat[idx])
end sub

sub _onCatSelected()
    idx = m.catGrid.itemSelected
    if idx >= 0 and idx < m.catFlat.count() then _play(m.catFlat[idx])
end sub

sub _onFavSelected()
    idx = m.favGrid.itemSelected
    if idx >= 0 and idx < m.favList.count() then _play(m.favList[idx])
end sub

sub _onSearchSelected()
    idx = m.searchGrid.itemSelected
    if idx >= 0 and idx < m.searchList.count() then _play(m.searchList[idx])
end sub

sub _onGuideSelected()
    idx = m.guideList.itemSelected
    if idx >= 0 and idx < m.channels.count() then _play(m.channels[idx])
end sub

' ================= PLAYER =================

sub _play(ch as object)
    if ch = invalid then return
    url = _str(ch, "streamUrl")
    if url = "" then url = _str(ch, "url")
    if url = "" then return

    m.currentChannel = ch
    content = createObject("roSGNode", "ContentNode")
    content.url          = url
    content.title        = _str(ch, "name")
    content.streamFormat = "hls"
    content.live         = true
    m.video.content  = content
    m.video.visible  = true
    m.video.control  = "play"

    m.playerName.text      = _str(ch, "name")
    meta = _str(ch, "countryLabel")
    cat  = _str(ch, "categoryLabel")
    if cat <> "" then meta = meta + " · " + cat
    m.playerMeta.text      = meta
    logo = _str(ch, "logo")
    m.playerLogo.uri       = logo
    m.playerInfoBg.visible = true
    m.playerLogo.visible   = (logo <> "")
    m.playerName.visible   = true
    m.playerMeta.visible   = true
    m.playerMsg.text       = "Cargando " + _str(ch, "name") + "…"
    m.playerMsg.visible    = true

    m.viewPlayer.visible = true
    m.mode = "player"
    _addRecent(_str(ch, "id"))
    m.top.setFocus(true)
end sub

sub _stopPlayer()
    m.video.control      = "stop"
    m.video.visible      = false
    m.viewPlayer.visible = false
    m.playerMsg.visible  = false
    m.mode = "view"
    if m.activeGrid <> invalid then
        m.activeGrid.setFocus(true)
    else
        _backToNav()
    end if
end sub

sub _onVideoState()
    st = m.video.state
    if st = "playing" then
        m.playerMsg.visible = false
    else if st = "buffering" then
        m.playerMsg.text    = "Cargando…"
        m.playerMsg.visible = true
    else if st = "error" then
        m.playerMsg.text    = "No se pudo reproducir el canal." + chr(10) + "Presiona Atrás para volver."
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
    m.ctxMenu.content  = content
    m.ctxBg.visible    = true
    m.ctxMenu.visible  = true
    m.ctxMenu.jumpToItem = 0
    m.mode = "ctx"
    m.ctxMenu.setFocus(true)
end sub

sub _closeContext()
    m.ctxBg.visible   = false
    m.ctxMenu.visible = false
    m.mode = "view"
    if m.activeGrid <> invalid then m.activeGrid.setFocus(true)
end sub

sub _ctxActivate()
    idx = m.ctxMenu.itemFocused
    ch  = m.ctxChannel
    if idx = 0 then
        id = _str(ch, "id")
        if _isFav(id) then _removeFav(id) else _addFav(id)
        if m.tab = 3 then _populateFav()
    else if idx = 1 then
        _closeContext()
        _play(ch)
        return
    end if
    _closeContext()
end sub

sub _openContextForActiveGrid()
    if m.tab = 2 then
        idx = m.guideList.itemFocused
        if idx >= 0 and idx < m.channels.count() then _openContext(m.channels[idx])
        return
    end if
    if m.activeGrid = invalid or m.activeFlatList = invalid then return
    idx = m.activeGrid.itemFocused
    if idx >= 0 and idx < m.activeFlatList.count() then
        _openContext(m.activeFlatList[idx])
    end if
end sub

' ================= SEARCH =================

sub _onSearchTextChange()
    q = m.kbd.text
    if q = invalid then q = ""
    q = lcase(q.trim())
    if q = "" then
        m.searchList = []
        m.searchGrid.content  = createObject("roSGNode", "ContentNode")
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
        m.searchGrid.content  = createObject("roSGNode", "ContentNode")
        m.searchEmpty.text    = "Sin resultados para """ + q + """"
        m.searchEmpty.visible = true
    else
        m.searchEmpty.visible = false
        content = createObject("roSGNode", "ContentNode")
        for each ch in results
            item = content.createChild("ContentNode")
            item.title = _str(ch, "name")
            item.shortDescriptionLine1 = _str(ch, "countryLabel")
            item.hdPosterUrl = _str(ch, "logo")
        end for
        m.searchGrid.content = content
    end if
end sub

' ================= SETTINGS =================

sub _buildSettingsMenu()
    content = createObject("roSGNode", "ContentNode")
    titles = ["Tema", "Controles parentales", "Limpiar datos", "Recargar canales", "Acerca de GioRoku"]
    for each t in titles
        n = content.createChild("ContentNode")
        n.title = t
    end for
    m.settingsList.content = content
    m.settingsInfo.text    = "Selecciona una opción."
end sub

sub _onSettingsFocused()
    idx = m.settingsList.itemFocused
    s   = _getSettings()
    if idx = 0 then
        m.settingsInfo.text = "Tema: Oscuro" + chr(10) + chr(10) + "GioRoku usa un tema oscuro optimizado para televisores."
    else if idx = 1 then
        st = iif(s.parentalEnabled, "Activado", "Desactivado")
        m.settingsInfo.text = "Controles parentales: " + st + chr(10) + chr(10) + "Pulsa OK para activar o desactivar."
    else if idx = 2 then
        m.settingsInfo.text = "Limpiar datos" + chr(10) + chr(10) + "Borra favoritos y canales recientes almacenados en el Roku."
    else if idx = 3 then
        m.settingsInfo.text = "Recargar canales" + chr(10) + chr(10) + "Descarga de nuevo la lista de canales desde la API." + chr(10) + "Útil después de importar una nueva lista M3U."
    else if idx = 4 then
        m.settingsInfo.text = "GioRoku v1.0" + chr(10) + "Tu televisión latina en Roku." + chr(10) + chr(10) + "Canales servidos desde GitHub Pages." + chr(10) + "Los streams provienen de fuentes públicas."
    end if
end sub

sub _onSettingsSelected()
    idx = m.settingsList.itemSelected
    s   = _getSettings()
    if idx = 1 then
        _setSetting("parentalEnabled", not s.parentalEnabled)
    else if idx = 2 then
        _regWrite("favorites", "[]")
        _regWrite("recentChannels", "[]")
        m.settingsInfo.text = "Datos borrados." + chr(10) + "Favoritos y recientes se han limpiado."
        return
    else if idx = 3 then
        m.settingsInfo.text = "Recargando canales…" + chr(10) + "La lista se actualizará en breve."
        _load()
        return
    end if
    _onSettingsFocused()
end sub

' ================= KEY HANDLING =================

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    ' Player mode — Back exits, Up/Down changes channel.
    if m.mode = "player" then
        if key = "back" then
            _stopPlayer()
        else if key = "up" then
            _channelStep(1)
        else if key = "down" then
            _channelStep(-1)
        else if key = "options" then
            _openContext(m.currentChannel)
        end if
        return true
    end if

    ' Context menu mode.
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

    ' Nav mode — left/right cycles tabs, OK/down enters the view.
    if m.mode = "nav" then
        if key = "left" then
            _highlightTab((m.tab + 5) mod 6)
            return true
        else if key = "right" then
            _highlightTab((m.tab + 1) mod 6)
            return true
        else if key = "OK" or key = "down" then
            _enterView()
            return true
        end if
        return false
    end if

    ' Search mode.
    if m.mode = "search" then
        if key = "back" then
            if m.searchFocus = "kbd" and m.searchList.count() > 0 then
                m.searchFocus = "grid"
                m.searchGrid.setFocus(true)
            else
                _backToNav()
            end if
            return true
        else if key = "up" and m.searchFocus = "grid" then
            m.searchFocus = "kbd"
            m.kbd.setFocus(true)
            return true
        end if
        return false
    end if

    ' View mode.
    if key = "back" then
        _backToNav()
        return true
    else if key = "up" then
        ' Return to tab bar from the first row/item of any widget.
        atTop = false
        if m.tab = 0 then
            if m.homeGrid.itemFocused < 4 then atTop = true
        else if m.tab = 1 then
            if m.catGrid.itemFocused < 4 then atTop = true
        else if m.tab = 2 then
            if m.guideList.itemFocused = 0 then atTop = true
        else if m.tab = 3 then
            if m.favGrid.itemFocused < 6 then atTop = true
        else if m.tab = 5 then
            if m.settingsList.itemFocused = 0 then atTop = true
        end if
        if atTop then
            _backToNav()
            return true
        end if
        return false
    else if key = "options" then
        _openContextForActiveGrid()
        return true
    end if
    return false
end function

' ================= STORAGE =================

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
    raw      = _regRead("settings")
    defaults = {parentalEnabled: false}
    if raw = invalid or raw = "" then return defaults
    p = parseJSON(raw)
    if type(p) <> "roAssociativeArray" then return defaults
    for each k in defaults
        if p[k] = invalid then p[k] = defaults[k]
    end for
    return p
end function

sub _setSetting(key as string, value as dynamic)
    s      = _getSettings()
    s[key] = value
    _regWrite("settings", formatJSON(s))
end sub

' ================= HELPERS =================

sub _showMessage(text as string)
    m.message.text    = text
    m.message.visible = true
end sub

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

function iif(cond as boolean, a as dynamic, b as dynamic) as dynamic
    if cond then return a
    return b
end function
