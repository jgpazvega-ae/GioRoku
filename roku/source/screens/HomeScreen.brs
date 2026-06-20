sub init()
    m.navBar = m.top.findNode("navBar")
    m.rowList = m.top.findNode("rowList")
    m.currentTab = 0

    m.navBar.tabs = ["Inicio", "Live TV", "Guía", "Favoritos", "Buscar", "Ajustes"]
    m.navBar.observeField("selectedTab", "_onTabChange")
    m.rowList.observeField("itemSelected", "_onChannelSelected")
    m.rowList.observeField("rowItemSelected", "_onChannelSelected")

    m.top.observeField("channels", "_onDataReady")
    m.top.observeField("deepLink", "_handleDeepLink")

    m.rowList.setFocus(true)
end sub

sub _onDataReady()
    if m.top.channels = invalid then return
    _buildRows()
end sub

sub _buildRows()
    ch = m.top.channels
    storage = m.top.storage
    rowLabels = []
    rowData = []

    ' Continue Watching row
    recent = storage.getRecentChannels()
    if recent.count() > 0 then
        recentChannels = []
        for each r in recent
            c = ch.getChannel(r.id)
            if c <> invalid then recentChannels.push(c)
        end for
        if recentChannels.count() > 0 then
            rowLabels.push("Continuar viendo")
            rowData.push(_toContentList(recentChannels))
        end if
    end if

    ' Favorites row
    favIds = storage.getFavorites()
    if favIds.count() > 0 then
        favChannels = []
        for each id in favIds
            c = ch.getChannel(id)
            if c <> invalid then favChannels.push(c)
        end for
        if favChannels.count() > 0 then
            rowLabels.push("Favoritos")
            rowData.push(_toContentList(favChannels))
        end if
    end if

    ' Featured row
    featured = ch.featured()
    if featured.count() > 0 then
        rowLabels.push("Destacados")
        rowData.push(_toContentList(featured))
    end if

    ' All channels row (first 30)
    all = ch.allChannels
    if all.count() > 0 then
        slice = []
        for i = 0 to min(29, all.count() - 1)
            slice.push(all[i])
        end for
        rowLabels.push("Todos los canales")
        rowData.push(_toContentList(slice))
    end if

    m.rowList.content = _buildContentNode(rowLabels, rowData)
end sub

function _toContentList(channels as Object) as Object
    list = createObject("roSGNode", "ContentNode")
    for each ch in channels
        item = list.createChild("ContentNode")
        item.id = ch.id
        item.title = ch.name
        item.hdPosterUrl = ch.logo
        item.shortDescriptionLine1 = ch.countryLabel
        item.shortDescriptionLine2 = ch.categoryLabel
        item.streamUrl = ch.streamUrl
    end for
    return list
end function

function _buildContentNode(labels as Object, rows as Object) as Object
    root = createObject("roSGNode", "ContentNode")
    for i = 0 to labels.count() - 1
        section = root.createChild("ContentNode")
        section.title = labels[i]
        for j = 0 to rows[i].getChildCount() - 1
            section.appendChild(rows[i].getChild(j))
        end for
    end for
    return root
end function

sub _onTabChange()
    tab = m.navBar.selectedTab
    if tab = m.currentTab then return
    m.currentTab = tab

    if tab = 0 then
        ' Home — already here, rebuild rows
        _buildRows()
    else if tab = 1 then
        _navigateTo("LiveTVScreen")
    else if tab = 2 then
        _navigateTo("GuideScreen")
    else if tab = 3 then
        _navigateTo("FavoritesScreen")
    else if tab = 4 then
        _navigateTo("SearchScreen")
    else if tab = 5 then
        _navigateTo("SettingsScreen")
    end if
end sub

sub _onChannelSelected()
    selected = m.rowList.rowItemSelected
    if selected = invalid or selected.count() < 2 then return
    rowIdx = selected[0]
    itemIdx = selected[1]

    rowNode = m.rowList.content.getChild(rowIdx)
    if rowNode = invalid then return
    item = rowNode.getChild(itemIdx)
    if item = invalid then return

    ch = m.top.channels.getChannel(item.id)
    if ch = invalid then return

    _openPlayer(ch)
end sub

sub _openPlayer(channel as Object)
    m.top.storage.addRecentChannel(channel.id)
    player = createObject("roSGNode", "PlayerScreen")
    player.channel = channel
    player.channels = m.top.channels
    player.storage = m.top.storage
    m.top.getScene().appendChild(player)
    player.setFocus(true)
end sub

sub _navigateTo(screenName as String)
    screen = createObject("roSGNode", screenName)
    screen.channels = m.top.channels
    screen.storage = m.top.storage
    screen.api = m.top.api
    m.top.getScene().appendChild(screen)
    screen.setFocus(true)
end sub

sub _handleDeepLink()
    dl = m.top.deepLink
    if dl = invalid then return
    if dl.contentId = "guide" then
        _navigateTo("GuideScreen")
    else if dl.contentId = "search" then
        _navigateTo("SearchScreen")
    else
        ch = m.top.channels.getChannel(dl.contentId)
        if ch <> invalid then _openPlayer(ch)
    end if
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "up" then
            m.navBar.setFocus(true)
            return true
        else if key = "down" then
            m.rowList.setFocus(true)
            return true
        end if
    end if
    return false
end sub
