sub init()
    m.grid = m.top.findNode("channelGrid")
    m.contextMenu = m.top.findNode("contextMenu")
    m.contextBg = m.top.findNode("contextBg")
    m.tabAll = m.top.findNode("tabAll")
    m.tabCountry = m.top.findNode("tabCountry")
    m.tabCategory = m.top.findNode("tabCategory")

    m.activeFilter = "all"
    m.activeTab = 0
    m.contextChannel = invalid

    m.grid.observeField("itemSelected", "_onItemSelected")
    m.top.observeField("channels", "_onDataReady")

    m.grid.setFocus(true)
end sub

sub _onDataReady()
    _loadGrid("all", invalid)
end sub

sub _loadGrid(filterType as String, filterValue)
    ch = m.top.channels
    if ch = invalid then return

    if filterType = "country" then
        list = ch.byCountry(filterValue)
    else if filterType = "category" then
        list = ch.byCategory(filterValue)
    else
        list = ch.allChannels
    end if

    content = createObject("roSGNode", "ContentNode")
    for each item in list
        node = content.createChild("ContentNode")
        node.id = item.id
        node.title = item.name
        node.hdPosterUrl = item.logo
        node.shortDescriptionLine1 = item.countryLabel
        node.shortDescriptionLine2 = item.categoryLabel
    end for
    m.grid.content = content
end sub

sub _onItemSelected()
    idx = m.grid.itemSelected
    item = m.grid.content.getChild(idx)
    if item = invalid then return
    ch = m.top.channels.getChannel(item.id)
    if ch = invalid then return

    m.top.storage.addRecentChannel(ch.id)
    player = createObject("roSGNode", "PlayerScreen")
    player.channel = ch
    player.channels = m.top.channels
    player.storage = m.top.storage
    m.top.getScene().appendChild(player)
    player.setFocus(true)
end sub

sub _showContextMenu(ch as Object)
    m.contextChannel = ch
    labels = createObject("roSGNode", "ContentNode")
    favs = m.top.storage.getFavorites()
    isFav = false
    for each id in favs
        if id = ch.id then isFav = true
    end for

    l1 = labels.createChild("ContentNode")
    l1.title = iif(isFav, "Quitar de Favoritos", "Agregar a Favoritos")
    l2 = labels.createChild("ContentNode")
    l2.title = "Info del canal"
    l3 = labels.createChild("ContentNode")
    l3.title = "Cancelar"

    m.contextMenu.content = labels
    m.contextMenu.visible = true
    m.contextBg.visible = true
    m.contextMenu.setFocus(true)
end sub

sub _hideContextMenu()
    m.contextMenu.visible = false
    m.contextBg.visible = false
    m.grid.setFocus(true)
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if m.contextMenu.visible then
            if key = "OK" or key = "select" then
                idx = m.contextMenu.itemFocused
                if idx = 0 then
                    favs = m.top.storage.getFavorites()
                    isFav = false
                    for each id in favs
                        if id = m.contextChannel.id then isFav = true
                    end for
                    if isFav then
                        m.top.storage.removeFavorite(m.contextChannel.id)
                    else
                        m.top.storage.addFavorite(m.contextChannel.id)
                    end if
                end if
                _hideContextMenu()
                return true
            else if key = "back" then
                _hideContextMenu()
                return true
            end if
        else
            if key = "options" then
                idx = m.grid.itemFocused
                item = m.grid.content.getChild(idx)
                if item <> invalid then
                    ch = m.top.channels.getChannel(item.id)
                    if ch <> invalid then _showContextMenu(ch)
                end if
                return true
            else if key = "back" then
                m.top.getScene().removeChild(m.top)
                return true
            end if
        end if
    end if
    return false
end sub
