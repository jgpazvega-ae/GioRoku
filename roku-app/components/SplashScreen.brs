sub init()
    m.progressBar = m.top.findNode("progressBar")
    m.statusLabel = m.top.findNode("statusLabel")
    m.done        = false

    ' Offline-first: load bundled channels + movies instantly (no network needed)
    m.bundledChannels = _readBundled("pkg:/data/channels.json", "channels")
    m.bundledMovies   = _readBundled("pkg:/data/movies.json",   "movies")

    m.statusLabel.text  = m.bundledChannels.count().toStr() + " canales"
    m.progressBar.width = 480

    ' Proceed timer — PRIMARY path. Appended to the tree so it reliably fires
    ' even when LoadTask blocks. After this delay we always advance to Home.
    m.proceedTimer = createObject("roSGNode", "Timer")
    m.proceedTimer.duration = 2.5
    m.proceedTimer.repeat   = false
    m.proceedTimer.id       = "proceedTimer"
    m.top.appendChild(m.proceedTimer)
    m.proceedTimer.observeField("fire", "_onProceed")
    m.proceedTimer.control  = "start"

    ' Optional network refresh — runs in parallel, never blocks the transition
    m.netTimer = createObject("roSGNode", "Timer")
    m.netTimer.duration = 0.3
    m.netTimer.repeat   = false
    m.netTimer.id       = "netTimer"
    m.top.appendChild(m.netTimer)
    m.netTimer.observeField("fire", "_startLoad")
    m.netTimer.control  = "start"
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

    ' Network upgrade only if it returned more than the bundled baseline
    if netChannels.count() > m.bundledChannels.count() then
        _finish(netChannels)
    end if
end sub

sub _onProceed()
    ' Primary transition — always advance with bundled data (network may
    ' have already upgraded via _onTaskDone, in which case m.done is set)
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
