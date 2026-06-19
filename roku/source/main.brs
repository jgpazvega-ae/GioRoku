' GioRoku — Main entry point
' Initializes the SceneGraph scene and handles deep link parameters.

sub Main(args as Object)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    scene = screen.CreateScene("SplashScreen")
    screen.show()

    ' Handle deep link launch parameters
    if args.DoesExist("contentId") then
        scene.callFunc("setDeepLink", {
            contentId: args.contentId,
            mediaType: args.mediaType
        })
    end if

    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then
                return
            end if
        end if
    end while
end sub
