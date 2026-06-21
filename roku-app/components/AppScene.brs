sub init()
    m.splash    = m.top.findNode("splash")
    m.home      = m.top.findNode("home")
    m.livetv    = m.top.findNode("livetv")
    m.guide     = m.top.findNode("guide")
    m.movies    = m.top.findNode("movies")
    m.favorites = m.top.findNode("favorites")
    m.search    = m.top.findNode("search")
    m.settings  = m.top.findNode("settings")
    m.sidebar   = m.top.findNode("sidebar")
    m.player    = m.top.findNode("player")

    m.channels      = []
    m.allMovies     = []
    m.currentScreen  = "splash"
    m.sidebarOpen    = false
    m.channelNodes   = invalid
    m.liveTVContent  = invalid
    m.guideContent   = invalid

    m.home.observeField("navigate",        "_onNavigate")
    m.home.observeField("playItem",        "_onPlayItem")

    m.livetv.observeField("navigate",      "_onNavigate")
    m.livetv.observeField("playItem",      "_onPlayItem")

    m.guide.observeField("navigate",       "_onNavigate")
    m.guide.observeField("playItem",       "_onPlayItem")

    m.movies.observeField("navigate",      "_onNavigate")
    m.movies.observeField("playItem",      "_onPlayItem")

    m.favorites.observeField("navigate",   "_onNavigate")
    m.favorites.observeField("playItem",   "_onPlayItem")

    m.search.observeField("navigate",      "_onNavigate")
    m.search.observeField("playItem",      "_onPlayItem")
    m.search.observeField("searchQuery",   "_onSearchQuery")

    m.settings.observeField("navigate",    "_onNavigate")
    m.settings.observeField("reloadReq",   "_onReloadReq")

    m.sidebar.observeField("navigate",     "_onSidebarNavigate")

    m.player.observeField("done",          "_onPlayerDone")

    ' References to each screen's primary focusable control. Focus must land
    ' on these inner nodes (not the screen Group) or arrow keys do nothing.
    m.homeList     = m.home.findNode("rowList")
    m.livetvList   = m.livetv.findNode("chanList")
    m.guideList    = m.guide.findNode("guideList")
    m.moviesList   = m.movies.findNode("rowList")
    m.favList      = m.favorites.findNode("favList")
    m.searchKbd    = m.search.findNode("kbd")
    m.settingsList = m.settings.findNode("settingsList")

    ' --- Bulletproof startup --------------------------------------------
    ' Load bundled channels + movies SYNCHRONOUSLY on the render thread and
    ' go straight to Home. No Task, no Timer, no cross-component observer —
    ' those were silently failing to fire on this device and leaving the
    ' splash stuck on "Conectando…".
    m.channels  = _readBundled("pkg:/data/channels.json", "channels")
    m.allMovies = _readBundled("pkg:/data/movies.json",   "movies")
    _navigateTo("home")

    ' Background refresh from GitHub Pages — never blocks the UI. Home is
    ' already shown from bundled data; if the server returns MORE channels
    ' than bundled, we upgrade the list and refresh Home. Failure is a no-op.
    m.bgTask = createObject("roSGNode", "LoadTask")
    m.bgTask.baseUrl = "https://jgpazvega-ae.github.io/GioRoku/api/v1"
    m.bgTask.observeField("taskState", "_onBgRefresh")
    m.bgTask.control = "RUN"
end sub

sub _onBgRefresh()
    state = m.bgTask.taskState
    if state <> "done" then return
    res = m.bgTask.result
    if res = invalid or not res.DoesExist("channels") or res.channels = invalid then return
    ' Only upgrade if the network result has MORE channels than what's bundled.
    ' This prevents a downgrade when the network load cap returns fewer channels
    ' than the bundled data/channels.json.
    if res.channels.count() > m.channels.count() then
        m.channels      = res.channels
        m.channelNodes  = invalid
        m.liveTVContent = invalid
        m.guideContent  = invalid
        if m.currentScreen = "home" then _prepareHome()
    end if
end sub


function _readBundled(path as string, key as string) as object
    out = []
    raw = readAsciiFile(path)
    if raw <> "" then
        d = parseJSON(raw)
        if d <> invalid and d.DoesExist(key) and d[key] <> invalid then
            out = d[key]
        end if
    end if
    return out
end function


' ===================== NAVIGATION =====================

sub _navigateTo(screen as string)
    if screen = "" or screen = "none" then return

    ' Hide every screen
    ids = ["home","livetv","guide","movies","favorites","search","settings","splash"]
    for each id in ids
        n = m.top.findNode(id)
        if n <> invalid then n.visible = false
    end for
    m.sidebar.visible = false
    m.sidebarOpen     = false
    m.currentScreen   = screen

    ' Make the screen visible FIRST, then load its data, then focus its inner
    ' control. Setting focus while the screen is still hidden does not stick.
    if screen = "home" then
        m.home.visible = true
        _prepareHome()
        m.sidebar.activeItem = 0

    else if screen = "livetv" then
        m.livetv.visible = true
        _prepareLiveTV()
        m.sidebar.activeItem = 1

    else if screen = "guide" then
        m.guide.visible = true
        _prepareGuide()

    else if screen = "movies" then
        m.movies.visible = true
        _prepareMovies()
        m.sidebar.activeItem = 2

    else if screen = "favorites" then
        m.favorites.visible = true
        _prepareFavorites()
        m.sidebar.activeItem = 3

    else if screen = "search" then
        m.search.visible = true
        m.sidebar.activeItem = 4

    else if screen = "settings" then
        m.settings.visible = true
        m.sidebar.activeItem = 5
    end if

    _focusScreen(screen)
end sub

' Focus the primary inner control of a screen — never the screen Group,
' or the RowList/MarkupList never receives arrow keys.
sub _focusScreen(screen as string)
    if screen = "home" then
        if m.homeList <> invalid then m.homeList.setFocus(true)
    else if screen = "livetv" then
        if m.livetvList <> invalid then m.livetvList.setFocus(true)
    else if screen = "guide" then
        if m.guideList <> invalid then m.guideList.setFocus(true)
    else if screen = "movies" then
        if m.moviesList <> invalid then m.moviesList.setFocus(true)
    else if screen = "favorites" then
        if m.favList <> invalid then m.favList.setFocus(true)
    else if screen = "search" then
        if m.searchKbd <> invalid then m.searchKbd.setFocus(true)
    else if screen = "settings" then
        if m.settingsList <> invalid then m.settingsList.setFocus(true)
    end if
end sub

sub _onNavigate()
    allScreens = [m.home, m.livetv, m.guide, m.movies, m.favorites, m.search, m.settings]
    for each s in allScreens
        if s <> invalid then
            nav = s.navigate
            if nav <> "" and nav <> "none" then
                s.navigate = "none"
                if nav = "sidebar" then
                    _openSidebar()
                else
                    _navigateTo(nav)
                end if
                return
            end if
        end if
    end for
end sub

sub _openSidebar()
    m.sidebar.visible = true
    m.sidebarOpen     = true
    m.sidebar.setFocus(true)
end sub

sub _onSidebarNavigate()
    dest = m.sidebar.navigate
    if dest = "" or dest = "none" then return
    m.sidebar.navigate = "none"
    if dest = "close" then
        m.sidebar.visible = false
        m.sidebarOpen     = false
        _focusScreen(m.currentScreen)
    else
        _navigateTo(dest)
    end if
end sub

' ===================== PLAYBACK =====================

sub _onPlayItem()
    allScreens = [m.home, m.livetv, m.guide, m.movies, m.favorites, m.search]
    for each s in allScreens
        if s <> invalid and s.playItem <> invalid then
            item = s.playItem
            s.playItem = invalid
            _startPlayer(item)
            return
        end if
    end for
end sub

sub _startPlayer(item as object)
    if item = invalid then return
    m.player.visible = true
    m.player.content = item
    isLive = false
    if item.hasField("isLive") then isLive = item.isLive
    if isLive then
        m.player.allChannels = _buildChannelNodes()
    else
        m.player.allChannels = invalid
    end if
    m.player.setFocus(true)
end sub

sub _onPlayerDone()
    if not m.player.done then return
    m.player.done    = false
    m.player.content = invalid
    m.player.visible = false
    _focusScreen(m.currentScreen)
end sub

' ===================== SEARCH =====================

sub _onSearchQuery()
    q = m.search.searchQuery
    if q = invalid then q = ""
    q = lcase(q.trim())

    root = createObject("roSGNode", "ContentNode")
    if q <> "" then
        chRow = root.createChild("ContentNode")
        chRow.title = "Canales"
        n = 0
        for each ch in m.channels
            if n >= 40 then exit for
            hay = lcase(_displayName(ch) + " " + _str(ch, "categoryLabel") + " " + _str(ch, "countryLabel"))
            if instr(1, hay, q) > 0 then
                it = chRow.createChild("ContentNode")
                it.title       = _displayName(ch)
                it.hdPosterUrl = _str(ch, "logo")
                it.url         = _str(ch, "streamUrl")
                it.streamFormat = "hls"
                it.live        = true
                it.addFields({chId: _str(ch, "id"), isLive: true})
                n = n + 1
            end if
        end for

        mvRow = root.createChild("ContentNode")
        mvRow.title = "Películas"
        n = 0
        for each mv in m.allMovies
            if n >= 20 then exit for
            hay = lcase(_str(mv, "title") + " " + _str(mv, "genre"))
            if instr(1, hay, q) > 0 then
                it = mvRow.createChild("ContentNode")
                it.title       = _str(mv, "title")
                it.hdPosterUrl = _str(mv, "poster")
                it.url         = _str(mv, "streamUrl")
                it.streamFormat = "mp4"
                it.live        = false
                it.addFields({isLive: false})
                n = n + 1
            end if
        end for
    end if
    m.search.searchResults = root
end sub

' ===================== SETTINGS RELOAD =====================

sub _onReloadReq()
    if not m.settings.reloadReq then return
    m.settings.reloadReq   = false
    m.settings.reloadState = "loading"

    m.loadTask = createObject("roSGNode", "LoadTask")
    m.loadTask.baseUrl = "https://jgpazvega-ae.github.io/GioRoku/api/v1"
    m.loadTask.observeField("taskState", "_onReloadDone")
    m.loadTask.control = "RUN"
end sub

sub _onReloadDone()
    state = m.loadTask.taskState
    if state = "done" then
        res = m.loadTask.result
        if res <> invalid and res.DoesExist("channels") and res.channels <> invalid then
            m.channels      = res.channels
            m.channelNodes  = invalid
            m.liveTVContent = invalid
            m.guideContent  = invalid
        end if
        m.settings.reloadCount = m.channels.count()
        m.settings.reloadState = "done"
    else if state = "error" then
        m.settings.reloadState = "error"
    end if
end sub

' ===================== DATA BUILDERS =====================

function _buildChannelNodes() as object
    if m.channelNodes <> invalid then return m.channelNodes
    root = createObject("roSGNode", "ContentNode")
    n = 0
    for each ch in m.channels
        if n >= 3000 then exit for
        n = n + 1
        it = root.createChild("ContentNode")
        it.title       = _displayName(ch)
        it.hdPosterUrl = _str(ch, "logo")
        it.url         = _str(ch, "streamUrl")
        it.streamFormat = "hls"
        it.live        = true
        it.addFields({chId: _str(ch, "id"), chNum: _pad3(n), isLive: true})
    end for
    m.channelNodes = root
    return root
end function

sub _prepareHome()
    root = createObject("roSGNode", "ContentNode")

    recentIds = _getRecent()
    if recentIds.count() > 0 then
        row = root.createChild("ContentNode")
        row.title = "Continuar Viendo"
        for each id in recentIds
            ch = _findChannel(id)
            if ch <> invalid then
                it = row.createChild("ContentNode")
                it.title       = _displayName(ch)
                it.hdPosterUrl = _str(ch, "logo")
                it.url         = _str(ch, "streamUrl")
                it.streamFormat = "hls"
                it.live        = true
                chMeta = _str(ch, "countryLabel")
                chCat  = _str(ch, "categoryLabel")
                if chMeta <> "" and chCat <> "" then it.description = chMeta + " · " + chCat else it.description = chMeta + chCat
                it.addFields({chId: id, isLive: true})
            end if
        end for
        if row.getChildCount() = 0 then root.removeChild(row)
    end if

    row2 = root.createChild("ContentNode")
    row2.title = "TV en Vivo"
    n = 0
    for each ch in m.channels
        if n >= 60 then exit for
        it = row2.createChild("ContentNode")
        it.title       = _displayName(ch)
        it.hdPosterUrl = _str(ch, "logo")
        it.url         = _str(ch, "streamUrl")
        it.streamFormat = "hls"
        it.live        = true
        chMeta = _str(ch, "countryLabel")
        chCat  = _str(ch, "categoryLabel")
        if chMeta <> "" and chCat <> "" then it.description = chMeta + " · " + chCat else it.description = chMeta + chCat
        it.addFields({chId: _str(ch, "id"), isLive: true})
        n = n + 1
    end for

    row3 = root.createChild("ContentNode")
    row3.title = "Películas"
    n = 0
    for each mv in m.allMovies
        if n >= 30 then exit for
        it = row3.createChild("ContentNode")
        it.title       = _str(mv, "title")
        it.hdPosterUrl = _str(mv, "poster")
        it.url         = _str(mv, "streamUrl")
        it.streamFormat = "mp4"
        it.live        = false
        it.addFields({isLive: false, mvYear: _str(mv, "year"), mvGenre: _str(mv, "genre")})
        n = n + 1
    end for

    favIds = _getFavorites()
    if favIds.count() > 0 then
        row4 = root.createChild("ContentNode")
        row4.title = "Favoritos"
        for each id in favIds
            ch = _findChannel(id)
            if ch <> invalid then
                it = row4.createChild("ContentNode")
                it.title       = _displayName(ch)
                it.hdPosterUrl = _str(ch, "logo")
                it.url         = _str(ch, "streamUrl")
                it.streamFormat = "hls"
                it.live        = true
                chMeta = _str(ch, "countryLabel")
                chCat  = _str(ch, "categoryLabel")
                if chMeta <> "" and chCat <> "" then it.description = chMeta + " · " + chCat else it.description = chMeta + chCat
                it.addFields({chId: id, isLive: true})
            end if
        end for
        if row4.getChildCount() = 0 then root.removeChild(row4)
    end if

    m.home.rowData = root
end sub

sub _prepareLiveTV()
    _buildChannelNodes()
    if m.liveTVContent = invalid then
        content = createObject("roSGNode", "ContentNode")
        n = 0
        for each ch in m.channels
            n = n + 1
            it = content.createChild("ContentNode")
            it.title        = _displayName(ch)
            it.hdPosterUrl  = _str(ch, "logo")
            it.url          = _str(ch, "streamUrl")
            it.streamFormat = "hls"
            it.live         = true
            meta = _str(ch, "countryLabel")
            cat  = _str(ch, "categoryLabel")
            if meta <> "" and cat <> "" then
                it.description = meta + " · " + cat
            else
                it.description = meta + cat
            end if
            online = true
            if type(ch) = "roAssociativeArray" and ch.DoesExist("isOnline") then
                online = (ch.isOnline = true)
            end if
            it.addFields({chNum: _pad3(n), chId: _str(ch, "id"), chLive: online, isLive: true})
        end for
        m.liveTVContent = content
    end if
    m.livetv.channelData = m.liveTVContent
end sub

sub _prepareGuide()
    if m.guideContent = invalid then
        content = createObject("roSGNode", "ContentNode")
        n = 0
        for each ch in m.channels
            n = n + 1
            it = content.createChild("ContentNode")
            meta = _str(ch, "countryLabel")
            cat  = _str(ch, "categoryLabel")
            q    = ucase(_str(ch, "quality"))
            if cat <> "" then meta = meta + "  ·  " + cat
            if q <> "" then meta = meta + "  ·  " + q
            online = true
            if type(ch) = "roAssociativeArray" and ch.DoesExist("isOnline") then
                online = (ch.isOnline = true)
            end if
            it.title        = _displayName(ch)
            it.description  = meta
            it.hdPosterUrl  = _str(ch, "logo")
            it.url          = _str(ch, "streamUrl")
            it.streamFormat = "hls"
            it.live         = true
            it.addFields({chNum: _pad3(n), chLive: online, chId: _str(ch, "id"), isLive: true})
        end for
        m.guideContent = content
    end if
    m.guide.channelData = m.guideContent
end sub

sub _prepareMovies()
    root   = createObject("roSGNode", "ContentNode")
    genres = ["Comedia","Drama","Terror","Clásico","Aventura","Cine mudo","Ciencia ficción","Western","Romance","Acción","Crimen","Cine negro","Bélica","Animación","Misterio","Musical","Suspenso"]

    if m.allMovies.count() > 0 then
        pop = root.createChild("ContentNode")
        pop.title = "Populares"
        n = 0
        for each mv in m.allMovies
            if n >= 20 then exit for
            it = pop.createChild("ContentNode")
            it.title       = _str(mv, "title")
            it.hdPosterUrl = _str(mv, "poster")
            it.url         = _str(mv, "streamUrl")
            it.streamFormat = "mp4"
            it.live        = false
            it.addFields({isLive: false, mvYear: _str(mv, "year"), mvGenre: _str(mv, "genre")})
            n = n + 1
        end for
    end if

    grouped = {}
    for each mv in m.allMovies
        g = _str(mv, "genre")
        for each genre in genres
            if lcase(g) = lcase(genre) then
                if not grouped.DoesExist(genre) then grouped[genre] = []
                grouped[genre].push(mv)
                exit for
            end if
        end for
    end for

    for each genre in genres
        if grouped.DoesExist(genre) and grouped[genre].count() > 0 then
            row = root.createChild("ContentNode")
            row.title = genre
            for each mv in grouped[genre]
                it = row.createChild("ContentNode")
                it.title       = _str(mv, "title")
                it.hdPosterUrl = _str(mv, "poster")
                it.url         = _str(mv, "streamUrl")
                it.streamFormat = "mp4"
                it.live        = false
                it.addFields({isLive: false, mvYear: _str(mv, "year"), mvGenre: _str(mv, "genre")})
            end for
        end if
    end for

    m.movies.rowData = root
end sub

sub _prepareFavorites()
    content = createObject("roSGNode", "ContentNode")
    favIds  = _getFavorites()
    for each id in favIds
        ch = _findChannel(id)
        if ch <> invalid then
            it = content.createChild("ContentNode")
            it.title       = _displayName(ch)
            it.hdPosterUrl = _str(ch, "logo")
            it.url         = _str(ch, "streamUrl")
            it.streamFormat = "hls"
            it.live        = true
            meta = _str(ch, "countryLabel")
            cat  = _str(ch, "categoryLabel")
            if meta <> "" and cat <> "" then
                it.description = meta + " · " + cat
            else
                it.description = meta + cat
            end if
            it.addFields({chId: id, chLive: true, isLive: true})
        end if
    end for
    m.favorites.channelData = content
end sub

' ===================== HELPERS =====================

function _findChannel(id as string) as dynamic
    for each ch in m.channels
        if _str(ch, "id") = id then return ch
    end for
    return invalid
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.player.visible then return false
    ' Left arrow at scene level (fallback for screens that don't consume it)
    if key = "left" and not m.sidebarOpen then
        _openSidebar()
        return true
    end if
    ' Back at scene level — fires when Home screen's onKeyEvent doesn't consume Back
    ' (extra safety net in case Back bubbles past all screens)
    if key = "back" and not m.sidebarOpen and m.currentScreen = "home" then
        _openSidebar()
        return true
    end if
    return false
end function
