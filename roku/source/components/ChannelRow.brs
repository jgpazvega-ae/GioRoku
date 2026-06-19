sub init()
    m.rowTitle = m.top.findNode("rowTitle")
    m.cardContainer = m.top.findNode("cardContainer")
    m.leftHint = m.top.findNode("leftHint")
    m.rightHint = m.top.findNode("rightHint")

    m.CARD_W = 200
    m.CARD_GAP = 12
    m.focusedIdx = 0
    m.scrollOffset = 0
    m.VISIBLE_CARDS = 9

    m.top.observeField("title", "_onTitleSet")
    m.top.observeField("channels", "_onChannelsSet")
end sub

sub _onTitleSet()
    m.rowTitle.text = m.top.title
end sub

sub _onChannelsSet()
    channels = m.top.channels
    if channels = invalid then return

    while m.cardContainer.getChildCount() > 0
        m.cardContainer.removeChildIndex(0)
    end while

    for i = 0 to channels.count() - 1
        card = createObject("roSGNode", "ChannelCard")
        card.id = "card_" + i.toStr()
        card.channel = channels[i]
        card.translation = [i * (m.CARD_W + m.CARD_GAP), 0]
        m.cardContainer.appendChild(card)
    end for

    _updateScrollHints()
end sub

sub _updateScrollHints()
    channels = m.top.channels
    if channels = invalid then return
    m.leftHint.visible = m.scrollOffset > 0
    m.rightHint.visible = (m.scrollOffset + m.VISIBLE_CARDS) < channels.count()
end sub

sub _focusCard(idx as Integer)
    channels = m.top.channels
    if channels = invalid then return

    ' Unfocus previous
    oldCard = m.cardContainer.findNode("card_" + m.focusedIdx.toStr())
    if oldCard <> invalid then oldCard.focused = false

    m.focusedIdx = idx

    ' Scroll if necessary
    if idx >= m.scrollOffset + m.VISIBLE_CARDS then
        m.scrollOffset = idx - m.VISIBLE_CARDS + 1
    else if idx < m.scrollOffset then
        m.scrollOffset = idx
    end if

    m.cardContainer.translation = [-m.scrollOffset * (m.CARD_W + m.CARD_GAP), 0]

    ' Focus new
    newCard = m.cardContainer.findNode("card_" + idx.toStr())
    if newCard <> invalid then newCard.focused = true

    _updateScrollHints()
end sub

sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        channels = m.top.channels
        if channels = invalid then return false
        total = channels.count()

        if key = "right" then
            if m.focusedIdx < total - 1 then
                _focusCard(m.focusedIdx + 1)
            end if
            return true
        else if key = "left" then
            if m.focusedIdx > 0 then
                _focusCard(m.focusedIdx - 1)
            else
                return false  ' Let parent handle (go to nav bar)
            end if
            return true
        else if key = "OK" or key = "select" then
            m.top.selected = m.focusedIdx
            return true
        end if
    end if
    return false
end sub
