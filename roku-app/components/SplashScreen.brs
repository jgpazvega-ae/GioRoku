' SplashScreen is now purely visual. AppScene loads bundled channels
' synchronously and navigates straight to Home, so this component does
' no loading work and starts no Task. It is hidden almost immediately.
sub init()
    m.statusLabel = m.top.findNode("statusLabel")
    if m.statusLabel <> invalid then m.statusLabel.text = "Cargando…"
end sub
