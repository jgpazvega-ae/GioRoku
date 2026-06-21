sub init()
    m.progressBar = m.top.findNode("progressBar")
    m.statusLabel = m.top.findNode("statusLabel")
    m.done        = false

    ' Offline-first: load bundled channels + movies instantly (no network needed)
    m.bundledChannels = _readBundled("pkg:/data/channels.json", "channels")
    m.bundledMovies   = _readBundled("pkg:/data/movies.json",   "movies")

    m.statusLabel.text  = "Conectando…"
    m.progressBar.width = 120

    ' Kick off an optional network refresh (gets fresher/more channels if online)
    m.timer = createObject("roSGNode", "Timer")
    m.timer.duration = 0.3
    m.timer.repeat   = false
    m.timer.observeField("fire", "_startLoad")
    m.timer.control  = "start"

    ' Watchdog: if network is slow/unreachable, proceed with bundled data
    m.watchdog = createObject("roSGNode", "Timer")
    m.watchdog.duration = 8
    m.watchdog.repeat   = false
    m.watchdog.observeField("fire", "_onWatchdog")
    m.watchdog.control  = "start"
end sub

sub _startLoad()
    m.loadTask = createObject("roSGNode", "LoadTask")
    m.loadTask.baseUrl = "https://raw.githubusercontent.com/jgpazvega-ae/GioRoku/main/docs/api/v1"
    m.loadTask.observeField("taskState", "_onTaskDone")
    m.loadTask.control = "RUN"
end sub

sub _onTaskDone()
    state = m.loadTask.taskState
    if state <> "done" and state <> "error" then return

    netChannels = []
    if state = "done" then
        res = m.loadTask.result
        if res <> invalid and res.DoesExist("channels") and res.channels <> invalid then
            netChannels = res.channels
        end if
    end if

    ' Use whichever source has more channels (network upgrade vs bundled baseline)
    if netChannels.count() > m.bundledChannels.count() then
        _finish(netChannels)
    else
        _finish(m.bundledChannels)
    end if
end sub

sub _onWatchdog()
    ' Network took too long — proceed with bundled channels (never hang)
    _finish(m.bundledChannels)
end sub

sub _finish(channels as object)
    if m.done then return
    m.done = true

    m.progressBar.width = 960
    m.statusLabel.text  = channels.count().toStr() + " canales"

    m.top.result = {channels: channels, movies: m.bundledMovies}
    m.top.done   = true
end sub

function _readBundled(path as string, key as string) as object
    out = []
    raw = readAsciiFile(path)
    if raw <> "" then
        d = parseJSON(raw)
        if d <> invalid and d.DoesExist(key) and d[key] <> invalid then
            out = d[key]
        end if
    end if
    return out
end function
