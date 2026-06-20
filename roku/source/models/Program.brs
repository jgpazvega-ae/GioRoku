' Program model helper functions

function getCurrentProgram(channel as Object) as Object
    if channel.DoesExist("currentProgram") then return channel.currentProgram
    return invalid
end function

function getNextProgram(channel as Object) as Object
    if channel.DoesExist("nextProgram") then return channel.nextProgram
    return invalid
end function

function formatTimeRange(program as Object) as String
    if program = invalid then return ""
    startStr = ""
    endStr = ""
    if program.DoesExist("start") then startStr = _formatISOTime(program.start)
    if program.DoesExist("end") then endStr = _formatISOTime(program.end)
    if startStr = "" and endStr = "" then return "En vivo"
    if endStr = "" then return startStr
    return startStr + " - " + endStr
end function

function getProgressPercent(program as Object) as Float
    if program = invalid then return 0.0
    if not program.DoesExist("start") or not program.DoesExist("end") then return 0.0

    now = createObject("roDateTime")
    nowMs = now.AsSeconds()

    startDT = createObject("roDateTime")
    startDT.FromISO8601String(program.start)
    endDT = createObject("roDateTime")
    endDT.FromISO8601String(program.end)

    total = endDT.AsSeconds() - startDT.AsSeconds()
    if total <= 0 then return 0.0

    elapsed = nowMs - startDT.AsSeconds()
    if elapsed <= 0 then return 0.0
    if elapsed >= total then return 1.0
    return elapsed / total
end function

' Convert ISO 8601 string to local time display "7:30 PM"
function _formatISOTime(iso as String) as String
    if iso = invalid or iso = "" then return ""
    dt = createObject("roDateTime")
    dt.FromISO8601String(iso)
    h = dt.GetHours()
    mn = dt.GetMinutes()
    ampm = "AM"
    if h >= 12 then
        ampm = "PM"
        if h > 12 then h = h - 12
    end if
    if h = 0 then h = 12
    mins = mn.toStr()
    if mn < 10 then mins = "0" + mins
    return h.toStr() + ":" + mins + " " + ampm
end function
