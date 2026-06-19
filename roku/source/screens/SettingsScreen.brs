sub init()
    m.settingsList = m.top.findNode("settingsList")
    m.optionList = m.top.findNode("optionList")
    m.infoBlock = m.top.findNode("infoBlock")
    m.valuePanelTitle = m.top.findNode("valuePanelTitle")
    m.valuePanelDesc = m.top.findNode("valuePanelDesc")
    m.confirmBg = m.top.findNode("confirmBg")
    m.confirmText = m.top.findNode("confirmText")
    m.confirmList = m.top.findNode("confirmList")

    m.confirmVisible = false
    m.pendingAction = ""

    m.settingsList.observeField("itemFocused", "_onSettingFocused")
    m.settingsList.observeField("itemSelected", "_onSettingSelected")

    _buildMenu()
    m.settingsList.setFocus(true)
end sub

sub _buildMenu()
    items = createObject("roSGNode", "ContentNode")
    labels = ["Tema", "Pais preferido", "Controles parentales", "Datos y cache", "Acerca de"]
    for each label in labels
        node = items.createChild("ContentNode")
        node.title = label
    end for
    m.settingsList.content = items
end sub

sub _onSettingFocused()
    idx = m.settingsList.itemFocused
    m.optionList.visible = false
    m.infoBlock.visible = false

    if idx = 0 then
        m.valuePanelTitle.text = "Tema de la aplicacion"
        m.valuePanelDesc.text = "Selecciona el tema visual de GioRoku."
        settings = m.top.storage.getSettings()
        theme = "dark"
        if settings.DoesExist("theme") then theme = settings.theme
        opts = createObject("roSGNode", "ContentNode")
        o1 = opts.createChild("ContentNode")
        o1.title = iif(theme = "dark", "Oscuro (activo)", "Oscuro")
        o2 = opts.createChild("ContentNode")
        o2.title = iif(theme = "light", "Claro (activo)", "Claro")
        m.optionList.content = opts
        m.optionList.visible = true

    else if idx = 1 then
        m.valuePanelTitle.text = "Pais preferido"
        m.valuePanelDesc.text = "Filtra el contenido de inicio por pais."
        settings = m.top.storage.getSettings()
        country = "ALL"
        if settings.DoesExist("countryPref") then country = settings.countryPref
        opts = createObject("roSGNode", "ContentNode")
        countries = ["ALL", "MX", "AR", "CO", "CL", "PE", "UY", "VE", "EC", "BO"]
        for each c in countries
            node = opts.createChild("ContentNode")
            node.title = iif(c = country, c + " (activo)", c)
        end for
        m.optionList.content = opts
        m.optionList.visible = true

    else if idx = 2 then
        m.valuePanelTitle.text = "Controles parentales"
        m.valuePanelDesc.text = "Activa el PIN parental para restringir contenido para adultos."
        settings = m.top.storage.getSettings()
        enabled = false
        if settings.DoesExist("parentalEnabled") then enabled = settings.parentalEnabled
        opts = createObject("roSGNode", "ContentNode")
        o1 = opts.createChild("ContentNode")
        o1.title = iif(not enabled, "Desactivado (activo)", "Desactivado")
        o2 = opts.createChild("ContentNode")
        o2.title = iif(enabled, "Activado (activo)", "Activado")
        m.optionList.content = opts
        m.optionList.visible = true

    else if idx = 3 then
        m.valuePanelTitle.text = "Datos y cache"
        m.valuePanelDesc.text = "Gestiona los datos almacenados localmente."
        m.infoBlock.text = "Presiona OK para ver las opciones de cache."
        m.infoBlock.visible = true

    else if idx = 4 then
        m.valuePanelTitle.text = "Acerca de GioRoku"
        m.valuePanelDesc.text = ""
        m.infoBlock.text = "Version: 1.0.0" + chr(10) + "Fuente de datos: GioRoku API (GitHub Pages)" + chr(10) + "Plataforma: Roku SceneGraph / BrightScript" + chr(10) + chr(10) + "Desarrollado con codigo abierto." + chr(10) + "Los streams son de fuentes publicas de terceros."
        m.infoBlock.visible = true
    end if
end sub

sub _onSettingSelected()
    idx = m.settingsList.itemSelected
    if idx = 3 then
        _showCacheOptions()
    else if m.optionList.visible then
        m.optionList.setFocus(true)
    end if
end sub

sub _showCacheOptions()
    labels = createObject("roSGNode", "ContentNode")
    l1 = labels.createChild("ContentNode")
    l1.title = "Limpiar cache"
    l2 = labels.createChild("ContentNode")
    l2.title = "Cancelar"
    m.confirmText.text = "Limpiar todos los datos guardados?"
    m.confirmList.content = labels
    m.confirmBg.visible = true
    m.confirmText.visible = true
    m.confirmList.visible = true
    m.confirmVisible = true
    m.pendingAction = "clearCache"
    m.confirmList.setFocus(true)
end sub

sub _hideConfirm()
    m.confirmBg.visible = false
    m.confirmText.visible = false
    m.confirmList.visible = false
    m.confirmVisible = false
    m.pendingAction = ""
    m.settingsList.setFocus(true)
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if m.confirmVisible then
            if key = "OK" or key = "select" then
                idx = m.confirmList.itemFocused
                if idx = 0 and m.pendingAction = "clearCache" then
                    m.top.storage.clearAll()
                end if
                _hideConfirm()
                return true
            else if key = "back" then
                _hideConfirm()
                return true
            end if

        else if m.optionList.visible and m.optionList.hasFocus() then
            if key = "OK" or key = "select" then
                settingIdx = m.settingsList.itemFocused
                optIdx = m.optionList.itemFocused
                if settingIdx = 0 then
                    m.top.storage.setSetting("theme", iif(optIdx = 0, "dark", "light"))
                else if settingIdx = 1 then
                    countries = ["ALL", "MX", "AR", "CO", "CL", "PE", "UY", "VE", "EC", "BO"]
                    if optIdx < countries.count() then
                        m.top.storage.setSetting("countryPref", countries[optIdx])
                    end if
                else if settingIdx = 2 then
                    m.top.storage.setSetting("parentalEnabled", optIdx = 1)
                end if
                _onSettingFocused()
                m.settingsList.setFocus(true)
                return true
            else if key = "back" or key = "left" then
                m.settingsList.setFocus(true)
                return true
            end if

        else
            if key = "right" and m.optionList.visible then
                m.optionList.setFocus(true)
                return true
            else if key = "back" then
                m.top.getScene().removeChild(m.top)
                return true
            end if
        end if
    end if
    return false
end sub
