' SplashScreen.brs — Bootstrap loader. Runs in render thread (no Task) for correctness.

sub init()
    m.api      = APIService_Init()
    m.storage  = StorageService_Init()
    m.channels = ChannelService_Init()
    m.deepLink = invalid
    m.retryMode = false

    m.barFill     = m.top.findNode("barFill")
    m.statusLabel = m.top.findNode("statusLabel")
    m.errorBg     = m.top.findNode("errorBg")
    m.errorLabel  = m.top.findNode("errorLabel")
    m.retryLabel  = m.top.findNode("retryLabel")

    ' Brief delay so the splash frame renders before blocking HTTP calls
    m.startTimer = createObject("roSGNode", "Timer")
    m.startTimer.duration = 0.5
    m.startTimer.repeat = false
    m.startTimer.observeField("fire", "_startLoad")
    m.startTimer.control = "start"
end sub

sub setDeepLink(params as Object)
    m.deepLink = params
end sub

sub _startLoad()
    m.retryMode = false
    _hideError()
    _setProgress(0, "Conectando…")
    _doLoad()
end sub

sub _doLoad()
    _setProgress(10, "Obteniendo estado…")
    status = m.api.fetchStatus()
    if status = invalid then
        _showError("Sin conexión. Verifica tu red o recarga el canal.")
        return
    end if

    _setProgress(30, "Cargando categorías…")
    m.api.fetchCategories()

    _setProgress(50, "Cargando países…")
    m.api.fetchCountries()

    _setProgress(70, "Cargando canales…")
    page1 = m.api.fetchPage(1)
    if page1 <> invalid and page1.DoesExist("channels") then
        m.channels.addPage(1, page1.channels)
    end if

    _setProgress(100, "¡Listo!")
    _navigateToHome()
end sub

sub _navigateToHome()
    home = createObject("roSGNode", "HomeScreen")
    home.channels = m.channels
    home.storage  = m.storage
    home.api      = m.api
    if m.deepLink <> invalid then
        home.deepLink = m.deepLink
    end if
    m.top.appendChild(home)
    home.setFocus(true)
end sub

sub _showError(msg as String)
    m.errorLabel.text = msg
    m.errorBg.visible = true
    m.errorLabel.visible = true
    m.retryLabel.visible = true
    m.barFill.width = 0
    m.retryMode = true
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
    if press and m.retryMode then
        if key = "OK" or key = "select" then
            _startLoad()
            return true
        end if
    end if
    return false
end sub
