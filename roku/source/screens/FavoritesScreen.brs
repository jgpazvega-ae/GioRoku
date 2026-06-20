sub init()
    m.grid = m.top.findNode("favGrid")
    m.emptyLabel = m.top.findNode("emptyLabel")
    m.ctxBg = m.top.findNode("ctxBg")
    m.ctxMenu = m.top.findNode("ctxMenu")
    m.ctxVisible = false

    m.grid.observeField("itemSelected", "_onItemSelected")
    m.top.observeField("channels", "_reload")
    m.top.observeField("storage", "_reload")

    _reload()
    m.grid.setFocus(true)
end sub

sub _reload()
    ch = m.top.channels
    storage = m.top.storage
    if ch = invalid or storage = invalid then return

    favIds = storage.getFavorites()
    if favIds.count() = 0 then
        m.grid.content = createObject("roSGNode", "ContentNode")
        m.emptyLabel.visible = true
        return
    end if

    m.emptyLabel.visible = false
    content = createObject("roSGNode", "ContentNode")
    for each id in favIds
        item = ch.getChannel(id)
        if item <> invalid then
            node = content.createChild("ContentNode")
            node.id = item.id
            node.title = item.name
            node.hdPosterUrl = item.logo
            node.shortDescriptionLine1 = item.countryLabel
            node.shortDescriptionLine2 = item.categoryLabel
        end if
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

sub _showContext()
    idx = m.grid.itemFocused
    item = m.grid.content.getChild(idx)
    if item = invalid then return

    labels = createObject("roSGNode", "ContentNode")
    l1 = labels.createChild("ContentNode")
    l1.title = "Quitar de Favoritos"
    l2 = labels.createChild("ContentNode")
    l2.title = "Cancelar"

    m.ctxMenu.content = labels
    m.ctxBg.visible = true
    m.ctxMenu.visible = true
    m.ctxVisible = true
    m.ctxMenu.setFocus(true)
end sub

sub _hideContext()
    m.ctxBg.visible = false
    m.ctxMenu.visible = false
    m.ctxVisible = false
    m.grid.setFocus(true)
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if m.ctxVisible then
            if key = "OK" or key = "select" then
                idx = m.ctxMenu.itemFocused
                if idx = 0 then
                    gridIdx = m.grid.itemFocused
                    item = m.grid.content.getChild(gridIdx)
                    if item <> invalid then
                        m.top.storage.removeFavorite(item.id)
                        _reload()
                    end if
                end if
                _hideContext()
                return true
            else if key = "back" then
                _hideContext()
                return true
            end if
        else
            if key = "options" then
                _showContext()
                return true
            else if key = "back" then
                m.top.getScene().removeChild(m.top)
                return true
            end if
        end if
    end if
    return false
end sub
