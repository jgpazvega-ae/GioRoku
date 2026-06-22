sub init()
    m.kbd         = m.top.findNode("kbd")
    m.resultsHdr  = m.top.findNode("resultsHdr")
    m.resultsList = m.top.findNode("resultsList")
    m.emptyMsg    = m.top.findNode("emptyMsg")

    m.focus = "kbd"
    m.kbd.observeField("text", "_onText")
    m.resultsList.observeField("itemSelected", "_onItemSelected")
    m.kbd.setFocus(true)
end sub

sub _onText()
    q = m.kbd.text
    if q = invalid then q = ""
    m.top.searchQuery = q.trim()
end sub

sub _onResults()
    root = m.top.searchResults
    if root = invalid then return

    total = 0
    for r = 0 to root.getChildCount() - 1
        total = total + root.getChild(r).getChildCount()
    end for

    if total = 0 and m.top.searchQuery <> "" then
        m.resultsList.visible = false
        m.resultsHdr.visible  = false
        m.emptyMsg.text       = "Sin resultados para """ + m.top.searchQuery + """"
        m.emptyMsg.visible    = true
        return
    end if

    m.emptyMsg.visible = false

    if total = 0 then
        m.resultsList.visible = false
        m.resultsHdr.visible  = false
        return
    end if

    ' Flatten results into a single ContentNode list
    flatContent = createObject("roSGNode", "ContentNode")
    for r = 0 to root.getChildCount() - 1
        row = root.getChild(r)
        for i = 0 to row.getChildCount() - 1
            item = row.getChild(i)
            newItem = flatContent.createChild("ContentNode")
            newItem.title       = item.title
            newItem.hdPosterUrl = item.hdPosterUrl
            newItem.url         = item.url
            newItem.streamFormat = item.streamFormat
            newItem.live        = item.live
            newItem.description = row.title
            if item.hasField("chId")       then newItem.addFields({chId:       item.chId})
            if item.hasField("isLive")     then newItem.addFields({isLive:     item.isLive, chLive: item.isLive})
            if item.hasField("backupUrls") then newItem.addFields({backupUrls: item.backupUrls})
            if item.hasField("chColor")    then newItem.addFields({chColor:    item.chColor})
        end for
    end for

    m.resultsList.content = flatContent
    m.resultsHdr.text     = total.toStr() + " resultado(s)"
    m.resultsHdr.visible  = true
    m.resultsList.visible = true
end sub

sub _onItemSelected()
    idx     = m.resultsList.itemSelected
    content = m.resultsList.content
    if content = invalid then return
    if idx < 0 or idx >= content.getChildCount() then return
    item = content.getChild(idx)
    if item <> invalid then m.top.playItem = item
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left" then
        if m.focus = "kbd" then
            m.top.navigate = "sidebar"
            return true
        else
            m.focus = "kbd"
            m.kbd.setFocus(true)
            return true
        end if
    else if key = "right" then
        if m.focus = "kbd" and m.resultsList.visible then
            m.focus = "results"
            m.resultsList.setFocus(true)
            return true
        end if
    else if key = "back" then
        if m.focus = "results" then
            m.focus = "kbd"
            m.kbd.setFocus(true)
        else
            m.top.navigate = "sidebar"
        end if
        return true
    end if
    return false
end function
