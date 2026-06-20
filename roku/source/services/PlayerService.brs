' PlayerService.brs — Stream playback, channel history, backup URL handling

function PlayerService_Init() as object
    svc = {}
    svc.currentChannel = invalid
    svc.history        = []
    svc.MAX_HISTORY    = 20
    svc.createContent  = PlayerService_createContent
    svc.setChannel     = PlayerService_setChannel
    svc.getNext        = PlayerService_getNext
    svc.getPrev        = PlayerService_getPrev
    svc.getHistoryItem = PlayerService_getHistoryItem
    return svc
end function

function PlayerService_createContent(channel as object) as object
    content = createObject("roSGNode", "ContentNode")
    content.url         = channel.streamUrl
    content.title       = channel.name
    content.streamformat = "hls"
    content.live        = true
    if channel.logo <> invalid and channel.logo <> ""
        content.hdPosterUrl = channel.logo
        content.sdPosterUrl = channel.logo
    end if
    return content
end function

function PlayerService_setChannel(channel as object)
    if m.currentChannel <> invalid
        entry = { id: m.currentChannel.id, watchedAt: "" + createObject("roDateTime").asSeconds() }
        m.history.unshift(entry)
        if m.history.count() > m.MAX_HISTORY then m.history.pop()
    end if
    m.currentChannel = channel
end function

function PlayerService_getNext(allChannels as object, currentIndex as integer) as dynamic
    nextIdx = currentIndex + 1
    if nextIdx >= allChannels.count() then nextIdx = 0
    return allChannels[nextIdx]
end function

function PlayerService_getPrev(allChannels as object, currentIndex as integer) as dynamic
    prevIdx = currentIndex - 1
    if prevIdx < 0 then prevIdx = allChannels.count() - 1
    return allChannels[prevIdx]
end function

function PlayerService_getHistoryItem(index as integer) as dynamic
    if index >= 0 and index < m.history.count() then return m.history[index]
    return invalid
end function
