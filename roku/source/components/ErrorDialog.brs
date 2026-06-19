sub init()
    m.iconLabel = m.top.findNode("iconLabel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.msgLabel = m.top.findNode("msgLabel")
    m.actionList = m.top.findNode("actionList")

    m.top.observeField("errorType", "_onTypeChange")
    m.top.observeField("message", "_onMessageChange")
    m.actionList.observeField("itemSelected", "_onActionSelected")

    _onTypeChange()
    m.actionList.setFocus(true)
end sub

sub _onTypeChange()
    errType = m.top.errorType
    if errType = "network_error" then
        m.iconLabel.text = "!"
        m.titleLabel.text = "Sin conexion"
        _setActions(["Reintentar", "Salir"])
    else if errType = "stream_error" then
        m.iconLabel.text = "!"
        m.titleLabel.text = "Error de reproduccion"
        _setActions(["Reintentar", "Volver"])
    else if errType = "no_results" then
        m.iconLabel.text = "?"
        m.titleLabel.text = "Sin resultados"
        _setActions(["Volver"])
    else
        m.iconLabel.text = "!"
        m.titleLabel.text = "Error"
        _setActions(["Cerrar"])
    end if
    _onMessageChange()
end sub

sub _onMessageChange()
    m.msgLabel.text = m.top.message
end sub

sub _setActions(labels as Object)
    content = createObject("roSGNode", "ContentNode")
    for each lbl in labels
        node = content.createChild("ContentNode")
        node.title = lbl
    end for
    m.actionList.content = content
end sub

sub _onActionSelected()
    m.top.actionSelected = m.actionList.itemSelected
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "back" then
        m.top.actionSelected = m.actionList.content.getChildCount() - 1
        return true
    end if
    return false
end sub
