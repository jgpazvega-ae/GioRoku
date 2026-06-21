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

    m.channels    = []
    m.allMovies   = []
    m.currentScreen = "splash"
    m.sidebarOpen   = false
    m.channelNodes  = invalid

    m.splash.observeField("done",          "_onSplashDone")

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

    m.splash.setFocus(true)
end sub

' ===================== SPLASH DONE =====================

sub _onSplashDone()
    if not m.splash.done then return
    res = m.splash.result
    if res <> invalid then
        if res.DoesExist("channels") and res.channels <> invalid then
            m.channels = res.channels
        end if
        if res.DoesExist("movies") and res.movies <> invalid then
            m.allMovies = res.movies
        end if
    end if
    _navigateTo("home")
end sub

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

    if screen = "home" then
        _prepareHome()
        m.home.visible = true
        m.home.setFocus(true)
        m.sidebar.activeItem = 0

    else if screen = "livetv" then
        _prepareLiveTV()
        m.livetv.visible = true
        m.livetv.setFocus(true)
        m.sidebar.activeItem = 1

    else if screen = "guide" then
        _prepareGuide()
        m.guide.visible = true
        m.guide.setFocus(true)

    else if screen = "movies" then
        _prepareMovies()
        m.movies.visible = true
        m.movies.setFocus(true)
        m.sidebar.activeItem = 2

    else if screen = "favorites" then
        _prepareFavorites()
        m.favorites.visible = true
        m.favorites.setFocus(true)
        m.sidebar.activeItem = 3

    else if screen = "search" then
        m.search.visible = true
        m.search.setFocus(true)
        m.sidebar.activeItem = 4

    else if screen = "settings" then
        m.settings.visible = true
        m.settings.setFocus(true)
        m.sidebar.activeItem = 5
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
        n = m.top.findNode(m.currentScreen)
        if n <> invalid then n.setFocus(true)
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
    m.player.visible = false
    n = m.top.findNode(m.currentScreen)
    if n <> invalid then n.setFocus(true)
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
    m.loadTask.baseUrl = "https://raw.githubusercontent.com/jgpazvega-ae/GioRoku/main/docs/api/v1"
    m.loadTask.observeField("taskState", "_onReloadDone")
    m.loadTask.control = "RUN"
end sub

sub _onReloadDone()
    state = m.loadTask.taskState
    if state = "done" then
        res = m.loadTask.result
        if res <> invalid and res.DoesExist("channels") and res.channels <> invalid then
            m.channels = res.channels
            m.channelNodes = invalid
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
                it.addFields({chId: id, isLive: true})
            end if
        end for
        if row.getChildCount() = 0 then root.removeChild(row)
    end if

    row2 = root.createChild("ContentNode")
    row2.title = "TV en Vivo"
    n = 0
    for each ch in m.channels
        if n >= 30 then exit for
        it = row2.createChild("ContentNode")
        it.title       = _displayName(ch)
        it.hdPosterUrl = _str(ch, "logo")
        it.url         = _str(ch, "streamUrl")
        it.streamFormat = "hls"
        it.live        = true
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
                it.addFields({chId: id, isLive: true})
            end if
        end for
        if row4.getChildCount() = 0 then root.removeChild(row4)
    end if

    m.home.rowData = root
end sub

sub _prepareLiveTV()
    root = _buildChannelNodes()
    ' Build a new ContentNode with chLive field for GuideRow rendering
    content = createObject("roSGNode", "ContentNode")
    n = 0
    for each ch in m.channels
        n = n + 1
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
        online = true
        if type(ch) = "roAssociativeArray" and ch.DoesExist("isOnline") then
            online = (ch.isOnline = true)
        end if
        it.addFields({chNum: _pad3(n), chId: _str(ch, "id"), chLive: online, isLive: true})
    end for
    m.livetv.channelData = content
end sub

sub _prepareGuide()
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
        it.title       = _displayName(ch)
        it.description = meta
        it.hdPosterUrl = _str(ch, "logo")
        it.url         = _str(ch, "streamUrl")
        it.streamFormat = "hls"
        it.live        = true
        it.addFields({chNum: _pad3(n), chLive: online, chId: _str(ch, "id"), isLive: true})
    end for
    m.guide.channelData = content
end sub

sub _prepareMovies()
    root   = createObject("roSGNode", "ContentNode")
    genres = ["Action","Adventure","Comedy","Drama","Horror","Sci-Fi","Romance","Documentary","Animation","Thriller","Western","Musical","Mystery","Fantasy","Biography","History","Crime"]

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
    if key = "left" and not m.sidebarOpen then
        _openSidebar()
        return true
    end if
    return false
end function
