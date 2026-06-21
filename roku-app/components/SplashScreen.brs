sub init()
    m.progressBar = m.top.findNode("progressBar")
    m.statusLabel = m.top.findNode("statusLabel")
    m.done        = false

    m.timer = createObject("roSGNode", "Timer")
    m.timer.duration = 0.4
    m.timer.repeat   = false
    m.timer.observeField("fire", "_startLoad")
    m.timer.control  = "start"

    m.watchdog = createObject("roSGNode", "Timer")
    m.watchdog.duration = 25
    m.watchdog.repeat   = false
    m.watchdog.observeField("fire", "_onWatchdog")
    m.watchdog.control  = "start"
end sub

sub _onWatchdog()
    if m.done then return
    m.statusLabel.text = "Sin conexión – continuando sin canales"
    m.top.result = {channels: [], movies: []}
    m.top.done   = true
    m.done       = true
end sub

sub _startLoad()
    m.statusLabel.text  = "Conectando…"
    m.progressBar.width = 120
    m.loadTask = createObject("roSGNode", "LoadTask")
    m.loadTask.baseUrl = "https://raw.githubusercontent.com/jgpazvega-ae/GioRoku/main/docs/api/v1"
    m.loadTask.observeField("taskState", "_onTaskDone")
    m.loadTask.control = "RUN"
end sub

sub _onTaskDone()
    state = m.loadTask.taskState
    if state <> "done" and state <> "error" then return

    channels = []
    if state = "done" then
        res = m.loadTask.result
        if res <> invalid and res.DoesExist("channels") and res.channels <> invalid then
            channels = res.channels
        end if
    end if

    m.progressBar.width = 640
    m.statusLabel.text  = channels.count().toStr() + " canales"

    movies = []
    raw = readAsciiFile("pkg:/data/movies.json")
    if raw <> "" then
        d = parseJSON(raw)
        if d <> invalid and d.DoesExist("movies") and d.movies <> invalid then
            movies = d.movies
        end if
    end if

    m.progressBar.width = 960
    m.statusLabel.text  = "Listo"

    m.top.result = {channels: channels, movies: movies}
    m.done       = true
    m.top.done   = true
end sub
