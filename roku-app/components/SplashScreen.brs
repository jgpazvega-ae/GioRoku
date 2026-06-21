sub init()
    m.progressBar = m.top.findNode("progressBar")
    m.statusLabel = m.top.findNode("statusLabel")
    m.done        = false

    ' Offline-first: bundled channels + movies load instantly (no network)
    m.bundledChannels = _readBundled("pkg:/data/channels.json", "channels")
    m.bundledMovies   = _readBundled("pkg:/data/movies.json",   "movies")

    m.statusLabel.text  = "Conectando…"
    m.progressBar.width = 320

    ' Start network load DIRECTLY (no Timer). The Task-completion observer
    ' is the only reliable trigger on this device; the LoadTask now has a
    ' hard 8s-per-request cap, so taskState always settles to done/error.
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

    ' ALWAYS finish here (reliable Task observer). Use the network list only
    ' if it returned more than the bundled baseline; otherwise use bundled.
    if netChannels.count() > m.bundledChannels.count() then
        _finish(netChannels)
    else
        _finish(m.bundledChannels)
    end if
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
