' ChannelService.brs — In-memory channel cache, search, filtering

function ChannelService_Init() as object
    svc = {}
    svc.allChannels   = []
    svc.loadedPages   = {}
    svc.totalPages    = 1
    svc.getChannel    = ChannelService_getChannel
    svc.search        = ChannelService_search
    svc.byCountry     = ChannelService_byCountry
    svc.byCategory    = ChannelService_byCategory
    svc.featured      = ChannelService_featured
    svc.addPage       = ChannelService_addPage
    svc.isPageLoaded  = ChannelService_isPageLoaded
    return svc
end function

function ChannelService_addPage(page as integer, channels as object)
    if m.loadedPages[str(page).trim()] = true then return
    for each ch in channels
        m.allChannels.push(ch)
    end for
    m.loadedPages[str(page).trim()] = true
end function

function ChannelService_isPageLoaded(page as integer) as boolean
    return m.loadedPages[str(page).trim()] = true
end function

function ChannelService_getChannel(id as string) as dynamic
    for each ch in m.allChannels
        if ch.id = id then return ch
    end for
    return invalid
end function

function ChannelService_search(query as string) as object
    q = lcase(query)
    results = []
    for each ch in m.allChannels
        name = lcase(ch.name)
        cat  = lcase(ch.categoryLabel + " " + ch.category)
        ctry = lcase(ch.countryLabel + " " + ch.country)
        if instr(1, name, q) > 0 or instr(1, cat, q) > 0 or instr(1, ctry, q) > 0
            results.push(ch)
        end if
        if results.count() >= 100 then exit for
    end for
    return results
end function

function ChannelService_byCountry(code as string) as object
    results = []
    for each ch in m.allChannels
        if ch.country = code then results.push(ch)
    end for
    return results
end function

function ChannelService_byCategory(slug as string) as object
    results = []
    for each ch in m.allChannels
        if ch.category = slug then results.push(ch)
    end for
    return results
end function

function ChannelService_featured() as object
    results = []
    for each ch in m.allChannels
        if ch.isFeatured = true then results.push(ch)
    end for
    return results
end function
