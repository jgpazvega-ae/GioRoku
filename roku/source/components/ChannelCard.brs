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
    if isFocused then
        m.focusBorder.visible = true
        m.cardBg.color = "#262626"
        ' Scale up slightly via translation offset (SceneGraph animation alternative)
        m.top.translation = [m.top.translation[0] - 3, m.top.translation[1] - 3]
        m.cardBg.width = 206
        m.cardBg.height = 118
        m.logo.width = 206
        m.logo.height = 118
        m.focusBorder.width = 206
        m.focusBorder.height = 118
    else
        m.focusBorder.visible = false
        m.cardBg.color = "#1A1A1A"
        m.top.translation = [m.top.translation[0] + 3, m.top.translation[1] + 3]
        m.cardBg.width = 200
        m.cardBg.height = 112
        m.logo.width = 200
        m.logo.height = 112
        m.focusBorder.width = 200
        m.focusBorder.height = 112
    end if
end sub
