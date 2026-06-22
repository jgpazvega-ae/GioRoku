sub init()
    m.settingsList = m.top.findNode("settingsList")
    m.infoText     = m.top.findNode("infoText")

    content = createObject("roSGNode", "ContentNode")
    titles  = ["Controles parentales", "Limpiar datos", "Recargar canales", "Acerca de GioRoku"]
    for each t in titles
        n = content.createChild("ContentNode")
        n.title = t
    end for
    m.settingsList.content = content

    m.settingsList.observeField("itemFocused",  "_onFocused")
    m.settingsList.observeField("itemSelected", "_onSelected")
    m.settingsList.setFocus(true)
    _showInfo(0)
end sub

sub _onFocused()
    _showInfo(m.settingsList.itemFocused)
end sub

sub _showInfo(idx as integer)
    s = _getSettings()
    if idx = 0 then
        st = iif(s.parentalEnabled, "Activado", "Desactivado")
        m.infoText.text = "Controles parentales: " + st + chr(10) + chr(10) + "Pulsa OK para activar o desactivar." + chr(10) + chr(10) + "(Función en desarrollo — la configuración se guarda pero aún no filtra contenido.)"
    else if idx = 1 then
        m.infoText.text = "Limpiar datos" + chr(10) + chr(10) + "Borra favoritos y canales recientes almacenados en el Roku."
    else if idx = 2 then
        m.infoText.text = "Recargar canales" + chr(10) + chr(10) + "Restaura la lista de canales latinos incluida en la app." + chr(10) + "Útil si la vista quedó en un estado inesperado."
    else if idx = 3 then
        m.infoText.text = "GioRoku v2.0" + chr(10) + "Tu televisión latina en Roku." + chr(10) + chr(10) + "408 canales LATAM incluidos en la app." + chr(10) + "Películas de dominio público (Internet Archive)." + chr(10) + chr(10) + "github.com/jgpazvega-ae/GioRoku"
    end if
end sub

sub _onSelected()
    idx = m.settingsList.itemSelected
    s   = _getSettings()
    if idx = 0 then
        _setSetting("parentalEnabled", not s.parentalEnabled)
        _showInfo(0)
    else if idx = 1 then
        _clearStorage()
        m.infoText.text = "Datos borrados." + chr(10) + "Favoritos y recientes se han limpiado."
    else if idx = 2 then
        m.infoText.text = "Recargando canales…"
        m.top.reloadReq = true
    end if
end sub

sub _onReloadState()
    st = m.top.reloadState
    if st = "done" then
        n = m.top.reloadCount
        m.infoText.text = "Canales recargados." + chr(10) + n.toStr() + " canales disponibles."
    else if st = "error" then
        m.infoText.text = "Error al restaurar." + chr(10) + "No se pudo leer la lista de canales."
    else if st = "loading" then
        m.infoText.text = "Restaurando canales…"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left" then
        m.top.navigate = "sidebar"
        return true
    else if key = "back" then
        m.top.navigate = "sidebar"
        return true
    end if
    return false
end function
