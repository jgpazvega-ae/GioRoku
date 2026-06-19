sub init()
    m.msgLabel = m.top.findNode("msgLabel")
    m.spinner = m.top.findNode("spinner")
    m.overlay = m.top.findNode("overlay")

    m.top.observeField("message", "_onMessageChange")
    m.top.observeField("visible", "_onVisibleChange")
end sub

sub _onMessageChange()
    m.msgLabel.text = m.top.message
end sub

sub _onVisibleChange()
    v = m.top.visible
    m.overlay.visible = v
    m.spinner.visible = v
    m.msgLabel.visible = v
end sub
