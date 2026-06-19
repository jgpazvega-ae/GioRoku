sub init()
    m.api = APIService_Init()
    m.storage = StorageService_Init()
    m.channels = ChannelService_Init()
    m.deepLink = invalid
    m.retryMode = false

    m.barFill = m.top.findNode("barFill")
    m.statusLabel = m.top.findNode("statusLabel")
    m.errorBg = m.top.findNode("errorBg")
    m.errorLabel = m.top.findNode("errorLabel")
    m.retryLabel = m.top.findNode("retryLabel")

    _startLoad()
end sub

sub setDeepLink(params as Object)
    m.deepLink = params
end sub

sub _startLoad()
    m.retryMode = false
    _hideError()
    _setProgress(0, "Conectando…")

    m.loadTask = createObject("roSGNode", "Task")
    m.loadTask.functionName = "_loadData"
    m.loadTask.observeField("state", "_onTaskState")
    m.loadTask.control = "RUN"
end sub

' Runs in task thread — fetches bootstrap data
sub _loadData()
    port = createObject("roMessagePort")

    _setProgress(10, "Obteniendo estado…")
    status = m.api.fetchStatus()
    if status = invalid then
        m.top.getScene().findNode("errorLabel").text = "Sin conexión. Verifica tu red."
        m.top.getScene().findNode("errorBg").visible = true
        m.top.getScene().findNode("errorLabel").visible = true
        m.top.getScene().findNode("retryLabel").visible = true
        m.top.getScene().findNode("barFill").width = 0
        return
    end if

    _setProgress(30, "Cargando categorías…")
    cats = m.api.fetchCategories()

    _setProgress(50, "Cargando países…")
    countries = m.api.fetchCountries()

    _setProgress(70, "Cargando canales…")
    page1 = m.api.fetchPage(1)
    if page1 <> invalid and page1.DoesExist("channels") then
        m.channels.addPage(1, page1.channels)
    end if

    _setProgress(100, "Listo")

    ' Store bootstrap data in scene fields for main thread pickup
    scene = m.top.getScene()
    scene.findNode("statusLabel").text = "Listo"

    ' Signal completion via field
    m.top.loadComplete = true
end sub

sub _onTaskState()
    if m.loadTask.state = "done" then
        if m.top.findNode("errorBg").visible = true then
            ' Error shown — wait for user
            m.retryMode = true
        else
            _navigateToHome()
        end if
    end if
end sub

sub _navigateToHome()
    home = createObject("roSGNode", "HomeScreen")
    home.channels = m.channels
    home.storage = m.storage
    home.api = m.api
    if m.deepLink <> invalid then
        home.deepLink = m.deepLink
    end if
    m.top.getScene().appendChild(home)
    home.setFocus(true)
    m.top.getScene().removeChild(m.top)
end sub

sub _setProgress(pct as Integer, msg as String)
    m.barFill.width = Int(600 * pct / 100)
    m.statusLabel.text = msg
end sub

sub _hideError()
    m.errorBg.visible = false
    m.errorLabel.visible = false
    m.retryLabel.visible = false
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if m.retryMode then
            if key = "OK" or key = "select" then
                _startLoad()
                return true
            end if
        end if
    end if
    return false
end sub
