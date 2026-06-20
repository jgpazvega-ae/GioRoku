sub init()
    m.cardBg = m.top.findNode("cardBg")
    m.focusBorder = m.top.findNode("focusBorder")
    m.logo = m.top.findNode("logo")
    m.statusDot = m.top.findNode("statusDot")
    m.nameLabel = m.top.findNode("nameLabel")

    m.top.observeField("channel", "_onChannelSet")
    m.top.observeField("focused", "_onFocusChange")
end sub

sub _onChannelSet()
    ch = m.top.channel
    if ch = invalid then return

    m.nameLabel.text = ch.name

    if ch.DoesExist("logo") and ch.logo <> "" then
        m.logo.uri = ch.logo
    end if

    isOnline = true
    if ch.DoesExist("isOnline") then isOnline = ch.isOnline
    if isOnline then
        m.statusDot.color = "#00C851"
    else
        m.statusDot.color = "#FF4444"
    end if
end sub

sub _onFocusChange()
    isFocused = m.top.focused
    m.focusBorder.visible = isFocused
    m.cardBg.color = iif(isFocused, "#262626", "#1A1A1A")
end sub
