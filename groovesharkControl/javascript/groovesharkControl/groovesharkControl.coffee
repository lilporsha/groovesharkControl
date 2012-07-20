
goog.provide 'gc'



(->

    groovesharkUrl = 'http://grooveshark.com/'
    groovesharkPreviewUrl = 'http://preview.grooveshark.com/'


    gc.injectGrooveshark = ->
        callWithGroovesharkTabIfIsOpened (tab) ->
            chrome.tabs.executeScript tab.id, file: 'javascript/contentscript.min.js'


    gc.createGroovesharkTab = ->
        properties =
            url: groovesharkUrl
        chrome.tabs.create properties

    #gc.createGroovesharkTabIfAlreadyIsnt = ->
    #    callWithGroovesharkTab ->

    gc.goToGroovesharkTab = ->
        callWithGroovesharkTab (tab) ->
            chrome.windows.update tab.windowId, focused: true
            chrome.tabs.update tab.id, selected: true


    gc.sendCommandToGrooveshark = (command, args) ->
        sendRequestToGrooveshark
            command: command
            args: args

    sendRequestToGrooveshark = (request) ->
        callWithGroovesharkTab (tab) ->
            chrome.tabs.sendRequest tab.id, request


    gc.msToHumanTime = (ms) ->
        s = ms / 1000
        minutes = parseInt s / 60
        seconds = parseInt s % 60
        if seconds < 10
            seconds = '0' + seconds
        minutes + ':' + seconds


    gc.callIfGroovesharkTabIsNotOpen = (callback) ->
        pass = ->
        callWithGroovesharkTab pass, callback

    callWithGroovesharkTabIfIsOpened = (callback) ->
        callWithGroovesharkTab callback, ->

    callWithGroovesharkTab = (callback, callbackIfGroovesharkIsNotOpen) ->
        chrome.windows.getAll populate: true, (windows) ->
            for win in windows
                for tab in win.tabs when isGroovesharkUrl tab.url
                    callback tab
                    return

            if typeof callbackIfGroovesharkIsNotOpen isnt 'undefined'
                callbackIfGroovesharkIsNotOpen()
            else
                gc.createGroovesharkTab()

    isGroovesharkUrl = (url) ->
        url.indexOf(groovesharkUrl) == 0 || url.indexOf(groovesharkPreviewUrl) == 0


    gc.showNotification = (stay) ->
        createNotification 'notification', stay

    gc.showLiteNotification = (stay) ->
        createNotification 'liteNotification', stay

    createNotification = (view, stay) ->
        if chrome.extension.getViews(type: 'notification').length > 1
            return
        notification = webkitNotifications.createHTMLNotification '../views/'+view+'.html'
        notification.show()

        cancelCountDownOfCloseOfNotification = () ->
            chrome.extension.getViews(type: 'notification').forEach((win) ->
                win.notification.cancelCountDownOfWindowClose()
            )
        setTimeout cancelCountDownOfCloseOfNotification, 100 if stay

)()
