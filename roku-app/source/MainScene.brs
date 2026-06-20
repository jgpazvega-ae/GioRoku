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
    for i = 0 to 6
        m.tabsNodes.push(m.top.findNode("tab" + i.toStr()))
    end for
    m.tabX = [228, 334, 455, 593, 669, 797, 898]
    m.tabW = [ 90, 105, 122,  60, 112,  85,  98]

    m.views = {
        home:     m.top.findNode("viewHome"),
        movies:   m.top.findNode("viewMovies"),
        live:     m.top.findNode("viewLive"),
        guide:    m.top.findNode("viewGuide"),
        fav:      m.top.findNode("viewFav"),
        search:   m.top.findNode("viewSearch"),
        settings: m.top.findNode("viewSettings")
    }

    ' Grid / list widgets
    m.homeGrid    = m.top.findNode("homeGrid")
    m.catGrid     = m.top.findNode("catGrid")
    m.moviesGrid  = m.top.findNode("moviesGrid")
    m.movKbd      = m.top.findNode("movKbd")
    m.movEmpty    = m.top.findNode("movEmpty")
    m.favGrid     = m.top.findNode("favGrid")
    m.favEmpty    = m.top.findNode("favEmpty")
    m.guideList   = m.top.findNode("guideList")
    m.searchGrid  = m.top.findNode("searchGrid")
    m.searchEmpty = m.top.findNode("searchEmpty")
    m.kbd         = m.top.findNode("kbd")
    m.settingsList  = m.top.findNode("settingsList")
    m.settingsInfo  = m.top.findNode("settingsInfo")

    ' Header clock
    m.clock = m.top.findNode("clock")

    ' Info panel (right side, shown for tabs 0-2)
    m.infoPanel  = m.top.findNode("infoPanel")
    m.infoName   = m.top.findNode("infoName")
    m.infoMeta   = m.top.findNode("infoMeta")
    m.infoLogo   = m.top.findNode("infoLogo")
    m.infoBadge  = m.top.findNode("infoBadge")
    m.infoNum    = m.top.findNode("infoNum")
    m.infoNumBg  = m.top.findNode("infoNumBg")

    ' Player + cable zap banner
    m.viewPlayer = m.top.findNode("viewPlayer")
    m.video      = m.top.findNode("video")
    m.playerMsg  = m.top.findNode("playerMsg")
    m.zapBanner  = m.top.findNode("zapBanner")
    m.zapNum     = m.top.findNode("zapNum")
    m.zapNumBg   = m.top.findNode("zapNumBg")
    m.zapLogo    = m.top.findNode("zapLogo")
    m.zapName    = m.top.findNode("zapName")
    m.zapMeta    = m.top.findNode("zapMeta")
    m.zapClock   = m.top.findNode("zapClock")
    m.zapHint    = m.top.findNode("zapHint")
    m.miniGuide  = m.top.findNode("miniGuide")
    m.miniList   = m.top.findNode("miniList")
    m.miniClock  = m.top.findNode("miniClock")

    ' Context menu
    m.ctxBg   = m.top.findNode("ctxBg")
    m.ctxMenu = m.top.findNode("ctxMenu")

    ' State
    m.channels       = []
    m.chNum          = {}
    m.countText      = ""
    m.homeFlat       = []
    m.catFlat        = []
    m.favList        = []
    m.searchList     = []
    m.allMovies      = []
    m.moviesList     = []
    m.tab            = 0
    m.mode           = "nav"
    m.searchFocus    = "kbd"
    m.movFocus       = "kbd"
    m.ctxChannel     = invalid
    m.activeGrid     = m.homeGrid
    m.activeFlatList = m.homeFlat
    m.currentChannel = invalid
    m.currentMovie   = invalid

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
    m.moviesGrid.observeField("itemSelected", "_onMoviesSelected")
    m.movKbd.observeField("text", "_onMoviesTextChange")
    m.miniList.observeField("itemSelected", "_onMiniSelected")
    m.video.observeField("state","_onVideoState")

    _buildSettingsMenu()
    _loadMovies()
    _highlightTab(3)
    m.top.setFocus(true)

    ' Live clock — ticks every second.
    m.clockTimer = createObject("roSGNode", "Timer")
    m.clockTimer.duration = 1
    m.clockTimer.repeat   = true
    m.clockTimer.observeField("fire", "_tick")
    m.clockTimer.control  = "start"
    _tick()

    ' Auto-hide timer for the zap banner.
    m.zapTimer = createObject("roSGNode", "Timer")
    m.zapTimer.duration = 5
    m.zapTimer.repeat   = false
    m.zapTimer.observeField("fire", "_hideZap")

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
        ' Assign stable cable-style channel numbers (1-based, master order).
        m.chNum = {}
        n = 0
        for each ch in list
            n = n + 1
            id = _str(ch, "id")
            if id <> "" then m.chNum[id] = n
        end for
        m.countText   = list.count().toStr() + " canales"
        _tick()
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
        ' Auto-enter guide so user can navigate immediately.
        if m.mode = "nav" and m.tab = 3 then
            m.mode = "view"
            m.guideList.setFocus(true)
        end if
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
                item.title = _displayName(ch)
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
                item.title = _displayName(ch)
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
    n = 0
    for each ch in m.channels
        n = n + 1
        item = content.createChild("ContentNode")
        meta = _str(ch, "countryLabel")
        cat  = _str(ch, "categoryLabel")
        q    = ucase(_str(ch, "quality"))
        if cat <> "" then meta = meta + "  ·  " + cat
        if q <> "" then meta = meta + "  ·  " + q
        online = true
        if type(ch) = "roAssociativeArray" and ch.DoesExist("isOnline") then online = (ch.isOnline = true)
        item.title       = _displayName(ch)
        item.description  = meta
        item.hdPosterUrl  = _str(ch, "logo")
        item.addFields({ chNum: _pad3(n), chLive: online })
    end for
    m.guideList.content = content
end sub

' Zero-pads a channel number to three digits, e.g. 7 -> "007".
function _pad3(n as integer) as string
    s = n.toStr()
    while len(s) < 3
        s = "0" + s
    end while
    return s
end function

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
            item.title = _displayName(ch)
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
        m.infoName.text     = "Selecciona un canal"
        m.infoMeta.text     = ""
        m.infoBadge.text    = ""
        m.infoLogo.uri      = ""
        m.infoNum.text      = ""
        m.infoNumBg.visible = false
        return
    end if
    m.infoName.text  = _displayName(ch)
    m.infoBadge.text = _badgeText(ch)
    num = _chNumStr(ch)
    if num <> "" then
        m.infoNum.text      = num
        m.infoNumBg.visible = true
    else
        m.infoNum.text      = ""
        m.infoNumBg.visible = false
    end if
    country = _str(ch, "countryLabel")
    cat     = _str(ch, "categoryLabel")
    if country <> "" and cat <> "" then
        m.infoMeta.text = country + " · " + cat
    else
        m.infoMeta.text = country + cat
    end if
    m.infoLogo.uri = _str(ch, "logo")
end sub

' Returns the zero-padded cable channel number for a channel, or "".
function _chNumStr(ch as object) as string
    id = _str(ch, "id")
    if id <> "" and m.chNum.DoesExist(id) then return _pad3(m.chNum[id])
    return ""
end function

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
    for k = 0 to 6
        if k = i then
            m.tabsNodes[k].color = "#FFFFFF"
        else
            m.tabsNodes[k].color = "#9CA3AF"
        end if
    end for
    m.underline.translation = [m.tabX[i], 36]
    m.underline.width       = m.tabW[i]

    keys = ["home","movies","live","guide","fav","search","settings"]
    for each name in keys
        m.views[name].visible = false
    end for
    m.views[keys[i]].visible = true

    ' Info bar: show for EN VIVO(0) and CATEGORÍAS(2) only.
    m.infoPanel.visible = (i = 0 or i = 2)

    if i = 0 and m.channels.count() = 0 and m.message.text <> "" then
        m.message.visible = true
    else
        m.message.visible = false
    end if

    if i = 4 then _populateFav()
end sub

sub _enterView()
    if m.tab = 0 then
        m.activeGrid     = m.homeGrid
        m.activeFlatList = m.homeFlat
        m.mode           = "view"
        m.homeGrid.setFocus(true)
    else if m.tab = 1 then
        m.mode        = "movsearch"
        m.movFocus    = "kbd"
        m.movKbd.setFocus(true)
    else if m.tab = 2 then
        m.activeGrid     = m.catGrid
        m.activeFlatList = m.catFlat
        m.mode           = "view"
        m.catGrid.setFocus(true)
    else if m.tab = 3 then
        m.activeGrid     = invalid
        m.activeFlatList = invalid
        m.mode           = "view"
        m.guideList.setFocus(true)
    else if m.tab = 4 then
        m.activeGrid     = m.favGrid
        m.activeFlatList = m.favList
        m.mode           = "view"
        m.favGrid.setFocus(true)
    else if m.tab = 5 then
        m.mode        = "search"
        m.searchFocus = "kbd"
        m.kbd.setFocus(true)
    else if m.tab = 6 then
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
    m.currentMovie   = invalid
    content = createObject("roSGNode", "ContentNode")
    content.url          = url
    content.title        = _str(ch, "name")
    content.streamFormat = "hls"
    content.live         = true
    m.video.content  = content
    m.video.visible  = true
    m.video.control  = "play"

    meta = _str(ch, "countryLabel")
    cat  = _str(ch, "categoryLabel")
    if cat <> "" then meta = meta + "  ·  " + cat
    q = ucase(_str(ch, "quality"))
    if q <> "" then meta = meta + "  ·  " + q

    _setZap(_chNumStr(ch), _displayName(ch), meta, _str(ch, "logo"), "▲▼ Cambiar canal     Atrás Salir")
    m.playerMsg.text    = "Cargando " + _displayName(ch) + "…"
    m.playerMsg.visible = true

    m.viewPlayer.visible = true
    m.mode = "player"
    _showZap()
    _addRecent(_str(ch, "id"))
    m.top.setFocus(true)
end sub

sub _stopPlayer()
    m.video.control      = "stop"
    m.video.visible      = false
    m.viewPlayer.visible = false
    m.playerMsg.visible  = false
    m.miniGuide.visible  = false
    _hideZap()
    if m.currentMovie <> invalid then
        m.currentMovie = invalid
        m.mode      = "movsearch"
        m.movFocus  = "grid"
        m.moviesGrid.setFocus(true)
        return
    end if
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
        if m.currentMovie <> invalid then
            m.playerMsg.text = "No se pudo reproducir esta película." + chr(10) + "Presiona Atrás para volver."
        else
            m.playerMsg.text = "No se pudo reproducir el canal." + chr(10) + "Presiona Atrás para volver."
        end if
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
    if m.tab = 3 then
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
            item.title = _displayName(ch)
            item.shortDescriptionLine1 = _str(ch, "countryLabel")
            item.hdPosterUrl = _str(ch, "logo")
        end for
        m.searchGrid.content = content
    end if
end sub

' ================= MOVIES (public-domain catalog, direct streams) =================

' Loads the bundled public-domain movie catalog (no network needed).
sub _loadMovies()
    m.allMovies = []
    raw = readAsciiFile("pkg:/data/movies.json")
    if raw <> invalid and raw <> "" then
        d = parseJSON(raw)
        if d <> invalid and type(d) = "roAssociativeArray" and d.DoesExist("movies") and d.movies <> invalid then
            m.allMovies = d.movies
        end if
    end if
    _populateMovies(m.allMovies)
end sub

' Builds the portrait poster grid for the given movie list.
sub _populateMovies(list as object)
    m.moviesList = list
    content = createObject("roSGNode", "ContentNode")
    for each mv in list
        item = content.createChild("ContentNode")
        item.title = _str(mv, "title")
        item.shortDescriptionLine1 = _str(mv, "year")
        item.shortDescriptionLine2 = _str(mv, "genre")
        item.hdPosterUrl = _str(mv, "poster")
    end for
    m.moviesGrid.content = content
    if list.count() = 0 then
        m.movEmpty.visible = true
    else
        m.movEmpty.visible = false
    end if
end sub

' Filters the catalog by title/genre as the user types.
sub _onMoviesTextChange()
    q = m.movKbd.text
    if q = invalid then q = ""
    q = lcase(q.trim())
    if q = "" then
        _populateMovies(m.allMovies)
        return
    end if
    results = []
    for each mv in m.allMovies
        hay = lcase(_str(mv, "title") + " " + _str(mv, "genre"))
        if instr(1, hay, q) > 0 then results.push(mv)
    end for
    if results.count() = 0 then
        m.moviesList = []
        m.moviesGrid.content = createObject("roSGNode", "ContentNode")
        m.movEmpty.text    = "Sin resultados para """ + q + """"
        m.movEmpty.visible = true
    else
        _populateMovies(results)
    end if
end sub

sub _onMoviesSelected()
    idx = m.moviesGrid.itemSelected
    if idx >= 0 and idx < m.moviesList.count() then _playMovie(m.moviesList[idx])
end sub

' Plays a public-domain movie from its direct stream URL (Roku-native MP4).
sub _playMovie(mv as object)
    if mv = invalid then return
    url = _str(mv, "streamUrl")
    if url = "" then return

    m.currentMovie   = mv
    m.currentChannel = invalid

    content = createObject("roSGNode", "ContentNode")
    content.url          = url
    content.title        = _str(mv, "title")
    content.streamFormat = "mp4"
    m.video.content = content
    m.video.visible = true
    m.video.control = "play"

    meta = ""
    yr = _str(mv, "year")
    gn = _str(mv, "genre")
    if yr <> "" then meta = yr
    if gn <> "" then
        if meta <> "" then meta = meta + "  ·  "
        meta = meta + gn
    end if

    _setZap("", _str(mv, "title"), meta, _str(mv, "poster"), "Atrás Salir")
    m.playerMsg.text    = "Cargando " + _str(mv, "title") + "…"
    m.playerMsg.visible = true

    m.viewPlayer.visible = true
    m.mode = "player"
    _showZap()
    m.top.setFocus(true)
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

    ' Player mode — Back exits, Up/Down zaps channels, OK toggles the banner.
    if m.mode = "player" then
        if key = "back" then
            _stopPlayer()
        else if key = "up" then
            _channelStep(1)
        else if key = "down" then
            _channelStep(-1)
        else if key = "OK" then
            if m.currentMovie <> invalid then
                if m.zapBanner.visible then _hideZap() else _showZap()
            else
                _openMini()
            end if
        else if key = "options" then
            _openContext(m.currentChannel)
        end if
        return true
    end if

    ' Mini-guide (channel switcher over live video).
    if m.mode = "mini" then
        if key = "back" or key = "left" then
            _closeMini()
            return true
        end if
        return false
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
            _highlightTab((m.tab + 6) mod 7)
            return true
        else if key = "right" then
            _highlightTab((m.tab + 1) mod 7)
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

    ' Movies search mode.
    if m.mode = "movsearch" then
        if key = "back" then
            if m.movFocus = "kbd" and m.moviesList.count() > 0 then
                m.movFocus = "grid"
                m.moviesGrid.setFocus(true)
            else
                _backToNav()
            end if
            return true
        else if key = "up" and m.movFocus = "grid" then
            m.movFocus = "kbd"
            m.movKbd.setFocus(true)
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
        else if m.tab = 2 then
            if m.catGrid.itemFocused < 4 then atTop = true
        else if m.tab = 3 then
            if m.guideList.itemFocused = 0 then atTop = true
        else if m.tab = 4 then
            if m.favGrid.itemFocused < 6 then atTop = true
        else if m.tab = 6 then
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

' ================= CLOCK + ZAP BANNER =================

' Ticks once per second: refreshes the header clock, the date/count line and,
' while the player banner is visible, the banner clock.
sub _tick()
    t = _clockStr()
    if m.clock <> invalid then m.clock.text = t
    if m.status <> invalid then
        line = _dateStr()
        if m.countText <> "" then line = line + "   ·   " + m.countText
        m.status.text = line
    end if
    if m.zapBanner <> invalid and m.zapBanner.visible and m.zapClock <> invalid then
        m.zapClock.text = t
    end if
    if m.miniGuide <> invalid and m.miniGuide.visible and m.miniClock <> invalid then
        m.miniClock.text = t
    end if
end sub

function _clockStr() as string
    dt = createObject("roDateTime")
    dt.toLocalTime()
    h = dt.getHours()
    mi = dt.getMinutes()
    ampm = "a.m."
    h12 = h
    if h >= 12 then ampm = "p.m."
    if h12 = 0 then h12 = 12
    if h12 > 12 then h12 = h12 - 12
    mm = mi.toStr()
    if len(mm) < 2 then mm = "0" + mm
    return h12.toStr() + ":" + mm + " " + ampm
end function

function _dateStr() as string
    dt = createObject("roDateTime")
    dt.toLocalTime()
    days   = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
    months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
    dn = dt.getDayOfWeek()
    mo = dt.getMonth()
    day = days[0]
    if dn >= 0 and dn <= 6 then day = days[dn]
    mon = months[0]
    if mo >= 1 and mo <= 12 then mon = months[mo - 1]
    return day + " " + dt.getDayOfMonth().toStr() + " " + mon
end function

' Fills the zap banner fields. An empty number hides the red dial block (movies).
sub _setZap(num as string, name as string, meta as string, logo as string, hint as string)
    if num <> "" then
        m.zapNum.text      = num
        m.zapNumBg.visible = true
        m.zapLogo.uri      = logo
        m.zapLogo.visible  = (logo <> "")
        m.zapName.translation = [414, 876]
        m.zapMeta.translation = [416, 942]
    else
        m.zapNum.text      = ""
        m.zapNumBg.visible = false
        m.zapLogo.visible  = false
        m.zapLogo.uri      = ""
        m.zapName.translation = [48, 876]
        m.zapMeta.translation = [48, 942]
    end if
    m.zapName.text = name
    m.zapMeta.text = meta
    m.zapHint.text = hint
end sub

sub _showZap()
    m.zapClock.text     = _clockStr()
    m.zapBanner.visible = true
    m.zapTimer.control  = "stop"
    m.zapTimer.control  = "start"
end sub

sub _hideZap()
    if m.zapBanner <> invalid then m.zapBanner.visible = false
    if m.zapTimer <> invalid then m.zapTimer.control = "stop"
end sub

' ----- Quick channel guide while watching -----

sub _openMini()
    if m.channels.count() = 0 then return
    content = createObject("roSGNode", "ContentNode")
    n = 0
    for each ch in m.channels
        n = n + 1
        item = content.createChild("ContentNode")
        item.title = _pad3(n) + "   " + _displayName(ch)
    end for
    m.miniList.content = content
    ' Highlight the channel currently playing.
    cur = 0
    if m.currentChannel <> invalid then
        curId = _str(m.currentChannel, "id")
        for i = 0 to m.channels.count() - 1
            if _str(m.channels[i], "id") = curId then
                cur = i
                exit for
            end if
        end for
    end if
    m.miniClock.text    = _clockStr()
    m.miniList.jumpToItem = cur
    m.miniGuide.visible = true
    _hideZap()
    m.mode = "mini"
    m.miniList.setFocus(true)
end sub

sub _closeMini()
    m.miniGuide.visible = false
    m.mode = "player"
    m.top.setFocus(true)
end sub

sub _onMiniSelected()
    idx = m.miniList.itemSelected
    if idx >= 0 and idx < m.channels.count() then
        m.miniGuide.visible = false
        m.mode = "player"
        _play(m.channels[idx])
    end if
end sub

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

' Returns the channel name without inline quality/status annotations such as
' "(1080p)", "[Geo-blocked]" or "[Not 24/7]" so the grid looks clean and premium.
function _displayName(ch as object) as string
    name = _str(ch, "name")
    out  = ""
    depth = 0
    for i = 0 to len(name) - 1
        c = mid(name, i + 1, 1)
        if c = "(" or c = "[" then
            depth = depth + 1
        else if c = ")" or c = "]" then
            if depth > 0 then depth = depth - 1
        else if depth = 0 then
            out = out + c
        end if
    end for
    out = out.trim()
    ' Collapse any double spaces left behind.
    while instr(1, out, "  ") > 0
        out = _replaceAll(out, "  ", " ")
    end while
    if out = "" then return name
    return out
end function

function _replaceAll(s as string, find as string, repl as string) as string
    out = ""
    rest = s
    at  = instr(1, rest, find)
    while at > 0
        out  = out + left(rest, at - 1) + repl
        rest = mid(rest, at + len(find))
        at   = instr(1, rest, find)
    end while
    return out + rest
end function

' Builds the badge text shown in the info panel: live indicator + quality.
function _badgeText(ch as object) as string
    online = true
    if ch <> invalid and type(ch) = "roAssociativeArray" and ch.DoesExist("isOnline") then
        online = (ch.isOnline = true)
    end if
    if online then
        txt = "● EN VIVO"
    else
        txt = "● FUERA DE LÍNEA"
    end if
    q = ucase(_str(ch, "quality"))
    if q <> "" then txt = txt + "  ·  " + q
    return txt
end function

function iif(cond as boolean, a as dynamic, b as dynamic) as dynamic
    if cond then return a
    return b
end function
