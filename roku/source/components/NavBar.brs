sub init()
    m.container = m.top.findNode("tabContainer")
    m.activeBar = m.top.findNode("activeBar")
    m.tabWidths = []
    m.focusedTab = 0

    m.top.observeField("tabs", "_buildTabs")
    m.top.observeField("selectedTab", "_onSelectionChange")
end sub

sub _buildTabs()
    tabs = m.top.tabs
    if tabs = invalid then return

    ' Remove old labels
    while m.container.getChildCount() > 0
        m.container.removeChildIndex(0)
    end while
    m.tabWidths = []

    x = 0
    for i = 0 to tabs.count() - 1
        lbl = createObject("roSGNode", "Label")
        lbl.id = "tab_" + i.toStr()
        lbl.text = tabs[i]
        lbl.font = "font:MediumSystemFont"
        lbl.color = iif(i = m.focusedTab, "#FFFFFF", "#A0A0A0")
        lbl.translation = [x, 20]
        m.container.appendChild(lbl)

        ' Approximate width: 18px per char + 40px padding
        w = tabs[i].len() * 14 + 40
        m.tabWidths.push(w)
        x = x + w
    end for

    _updateActiveBar()
end sub

sub _onSelectionChange()
    m.focusedTab = m.top.selectedTab
    _highlightTabs()
    _updateActiveBar()
end sub

sub _highlightTabs()
    tabs = m.top.tabs
    if tabs = invalid then return
    for i = 0 to tabs.count() - 1
        lbl = m.container.findNode("tab_" + i.toStr())
        if lbl <> invalid then
            lbl.color = iif(i = m.focusedTab, "#FFFFFF", "#A0A0A0")
            lbl.font = iif(i = m.focusedTab, "font:MediumBoldSystemFont", "font:MediumSystemFont")
        end if
    end for
end sub

sub _updateActiveBar()
    if m.tabWidths.count() = 0 then return
    x = 40
    for i = 0 to m.focusedTab - 1
        x = x + m.tabWidths[i]
    end for
    tabW = m.tabWidths[m.focusedTab]
    m.activeBar.translation = [x, 69]
    m.activeBar.width = tabW - 20
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        tabs = m.top.tabs
        if tabs = invalid then return false

        if key = "left" then
            if m.focusedTab > 0 then
                m.top.selectedTab = m.focusedTab - 1
            end if
            return true
        else if key = "right" then
            if m.focusedTab < tabs.count() - 1 then
                m.top.selectedTab = m.focusedTab + 1
            end if
            return true
        else if key = "OK" or key = "select" then
            m.top.selectedTab = m.focusedTab
            return true
        end if
    end if
    return false
end sub
