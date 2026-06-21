sub init()
    m.rowList    = m.top.findNode("rowList")
    m.heroPoster = m.top.findNode("heroPoster")
    m.heroTitle  = m.top.findNode("heroTitle")
    m.heroMeta   = m.top.findNode("heroMeta")
    m.heroDesc   = m.top.findNode("heroDesc")
    m.emptyMsg   = m.top.findNode("emptyMsg")

    m.rowList.observeField("rowItemFocused",  "_onFocusChange")
    m.rowList.observeField("rowFocused",      "_onFocusChange")
    m.rowList.observeField("rowItemSelected", "_onItemSelected")
end sub

sub _onRowData()
    root = m.top.rowData
    if root = invalid then return
    m.rowList.content = root

    hasContent = false
    for r = 0 to root.getChildCount() - 1
        if root.getChild(r).getChildCount() > 0 then hasContent = true : exit for
    end for

    if hasContent then
        m.emptyMsg.visible = false
        _updateHeroFromIndex(0, 0)
        m.rowList.setFocus(true)
    else
        m.emptyMsg.text    = "No hay películas disponibles."
        m.emptyMsg.visible = true
    end if
end sub

sub _onFocusChange()
    _updateHeroFromIndex(m.rowList.rowFocused, m.rowList.rowItemFocused)
end sub

sub _updateHeroFromIndex(rowIdx as integer, itemIdx as integer)
    root = m.top.rowData
    if root = invalid then return
    if rowIdx < 0 or rowIdx >= root.getChildCount() then return
    row = root.getChild(rowIdx)
    if row = invalid or itemIdx < 0 or itemIdx >= row.getChildCount() then return
    item = row.getChild(itemIdx)
    if item = invalid then return

    m.heroPoster.uri = item.hdPosterUrl
    m.heroTitle.text = item.title
    meta = ""
    if item.hasField("mvYear") and item.mvYear <> "" then meta = item.mvYear
    if item.hasField("mvGenre") and item.mvGenre <> "" then
        if meta <> "" then meta = meta + "  ·  "
        meta = meta + item.mvGenre
    end if
    m.heroMeta.text = meta
    m.heroDesc.text = item.description
end sub

sub _onItemSelected()
    ri = m.rowList.rowFocused
    ii = m.rowList.rowItemFocused
    root = m.top.rowData
    if root = invalid then return
    if ri < 0 or ri >= root.getChildCount() then return
    row = root.getChild(ri)
    if row = invalid or ii < 0 or ii >= row.getChildCount() then return
    item = row.getChild(ii)
    if item <> invalid then m.top.playItem = item
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left" then
        m.top.navigate = "sidebar"
        return true
    else if key = "back" then
        m.top.navigate = "home"
        return true
    else if key = "options" then
        m.top.navigate = "sidebar"
        return true
    end if
    return false
end function
