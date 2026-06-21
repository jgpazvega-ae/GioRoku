sub init()
    m.rowList    = m.top.findNode("rowList")
    m.heroPoster = m.top.findNode("heroPoster")
    m.heroTitle  = m.top.findNode("heroTitle")
    m.heroBadge  = m.top.findNode("heroBadge")
    m.heroMeta   = m.top.findNode("heroMeta")
    m.heroDesc   = m.top.findNode("heroDesc")
    m.emptyMsg   = m.top.findNode("emptyMsg")

    m.rowList.observeField("rowItemFocused", "_onFocusChange")
    m.rowList.observeField("rowFocused",     "_onFocusChange")
    m.rowList.observeField("rowItemSelected","_onItemSelected")
end sub

sub _onRowData()
    root = m.top.rowData
    if root = invalid then return
    m.rowList.content = root

    ' Check for any content
    hasContent = false
    for r = 0 to root.getChildCount() - 1
        if root.getChild(r).getChildCount() > 0 then hasContent = true : exit for
    end for

    if not hasContent then
        m.emptyMsg.text    = "Aún no hay contenido." + chr(10) + "Importa una lista M3U desde la herramienta web."
        m.emptyMsg.visible = true
        m.heroTitle.text   = "Bienvenido a GioRoku"
        m.heroBadge.text   = ""
        m.heroMeta.text    = "Tu televisión latina"
        m.heroDesc.text    = "Importa tu lista de canales desde el portal web para empezar a ver TV en vivo."
    else
        m.emptyMsg.visible = false
        _updateHeroFromIndex(0, 0)
        m.rowList.setFocus(true)
    end if
end sub

sub _onFocusChange()
    ri = m.rowList.rowFocused
    ii = m.rowList.rowItemFocused
    _updateHeroFromIndex(ri, ii)
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

    isLive = false
    if item.hasField("isLive") then isLive = item.isLive

    if isLive then
        m.heroBadge.text  = "● EN VIVO"
        m.heroBadge.color = "#CC1F1F"
    else
        yr = ""
        gn = ""
        if item.hasField("mvYear") then yr = item.mvYear
        if item.hasField("mvGenre") then gn = item.mvGenre
        if yr <> "" and gn <> "" then
            m.heroBadge.text = yr + "  ·  " + gn
        else
            m.heroBadge.text = yr + gn
        end if
        m.heroBadge.color = "#9CA3AF"
    end if
    m.heroMeta.text = row.title
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
    if item = invalid then return
    m.top.playItem = item
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left" then
        m.top.navigate = "sidebar"
        return true
    else if key = "back" then
        ' RowList consumes left arrow; Back reliably bubbles, so use it to open the menu.
        m.top.navigate = "sidebar"
        return true
    else if key = "options" then
        ' Toggle favorite for focused item
        ri = m.rowList.rowFocused
        ii = m.rowList.rowItemFocused
        root = m.top.rowData
        if root <> invalid and ri >= 0 and ri < root.getChildCount() then
            row = root.getChild(ri)
            if row <> invalid and ii >= 0 and ii < row.getChildCount() then
                item = row.getChild(ii)
                if item <> invalid and item.hasField("chId") then
                    id = item.chId
                    if _isFav(id) then _removeFav(id) else _addFav(id)
                end if
            end if
        end if
        return true
    end if
    return false
end function
