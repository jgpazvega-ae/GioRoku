sub init()
    m.keyboard = m.top.findNode("keyboard")
    m.grid = m.top.findNode("resultsGrid")
    m.noResultsLabel = m.top.findNode("noResultsLabel")

    m.keyboard.observeField("text", "_onQueryChange")
    m.grid.observeField("itemSelected", "_onItemSelected")
    m.top.observeField("query", "_applyPrefilledQuery")

    m.keyboard.setFocus(true)
end sub

sub _applyPrefilledQuery()
    q = m.top.query
    if q <> invalid and q <> "" then
        m.keyboard.text = q
    end if
end sub

sub _onQueryChange()
    q = m.keyboard.text
    if q = invalid then q = ""
    q = q.trim()

    ch = m.top.channels
    if ch = invalid then return

    if q = "" then
        _populateGrid(ch.allChannels)
        m.noResultsLabel.visible = false
        return
    end if

    results = ch.search(q)
    if results.count() = 0 then
        m.grid.content = createObject("roSGNode", "ContentNode")
        m.noResultsLabel.text = "Sin resultados para """ + q + """"
        m.noResultsLabel.visible = true
    else
        _populateGrid(results)
        m.noResultsLabel.visible = false
    end if
end sub

sub _populateGrid(list as Object)
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

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "down" and m.keyboard.hasFocus() then
            if m.grid.content <> invalid and m.grid.content.getChildCount() > 0 then
                m.grid.setFocus(true)
                return true
            end if
        else if key = "up" and m.grid.hasFocus() then
            m.keyboard.setFocus(true)
            return true
        else if key = "back" then
            m.top.getScene().removeChild(m.top)
            return true
        end if
    end if
    return false
end sub
