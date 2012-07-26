
goog.provide 'gc.ViewUpdater'

goog.require 'goog.dom'
goog.require 'goog.events'
goog.require 'gc'
goog.require 'gc.Slider'



gc.ViewUpdater = ->



goog.scope ->
    `var VU = gc.ViewUpdater`

    # Init.


    VU::initListeners = () ->
        that = @

        chrome.extension.onRequest.addListener (request, sender, sendResponse) ->
            that.update request
        # Force update now and create Grooveshark tab if isn't openned.
        gc.sendCommandToGrooveshark 'refresh'

        chrome.tabs.onRemoved.addListener (tabId, removeInfo) ->
            gc.callIfGroovesharkTabIsNotOpen ->
                window.close()


    VU::initProgressbar = () ->
        that = @
        @progressbar = new gc.Slider 'progressbar'
        @progressbar.init () ->
            gc.sendCommandToGrooveshark 'seekTo', seekTo: that.progressbar.getValue()


    VU::initVolumeSlider = () ->
        that = @
        @volumeSlider = new gc.Slider 'volumeSlider', true
        @volumeSlider.init () ->
            gc.sendCommandToGrooveshark 'setVolume', volume: that.volumeSlider.getValue()


    # Player options.


    VU::updatePlayer = (player) ->
        @updatePlayerOptions player
        @updatePlayerVolume player

    VU::updatePlayerOptions = (player) ->
        goog.dom.classes.set goog.dom.getElement('shuffle'), player.shuffle
        goog.dom.classes.set goog.dom.getElement('loop'), player.loop
        goog.dom.classes.set goog.dom.getElement('crossfade'), player.crossfade

    VU::updatePlayerVolume = (player) ->
        @volumeSlider.setValue player.volume

        elm = goog.dom.getElement 'volume'
        classesToRemove = ['mute', 'volume0', 'volume20', 'volume40', 'volume60', 'volume80', 'volume100']
        if player.isMute
            volumeClass = 'mute'
        else
            volumeClass = 'volume' + Math.round(player.volume / (100 / 5)) * 20
        goog.dom.classes.addRemove elm, classesToRemove, volumeClass


    # Current song.


    VU::updateCurrentSong = (song) ->
        @updateCurrentSongInformation song
        @updateCurrentSongImage song
        @updateCurrentSongOptions song

    VU::updateCurrentSongInformation = (song) ->
        elm = goog.dom.getElement 'songName'
        goog.dom.setProperties elm, textContent: song.songName, title: song.songName

        elm = goog.dom.getElement 'artistName'
        goog.dom.setProperties elm, textContent: song.artistName, title: song.artistName
        @_addLink elm, () -> gc.goToPageWithArtist song.artistId

        elm = goog.dom.getElement 'albumName'
        goog.dom.setProperties elm, textContent: song.albumName, title: song.albumName
        @_addLink elm, () -> gc.goToPageWithAlbum song.albumId

    VU::updateCurrentSongImage = (song) ->
        elm = goog.dom.getElement 'albumArt'
        elm.src = song.albumImage
        @_addLink elm, () -> gc.goToPageWithAlbum song.albumId

    VU::updateCurrentSongOptions = (song) ->
        goog.dom.classes.enable goog.dom.getElement('library'), 'disable', !song.fromLibrary
        goog.dom.classes.enable goog.dom.getElement('favorite'), 'disable', !song.isFavorite
        goog.dom.classes.enable goog.dom.getElement('smile'), 'active', song.isSmile
        goog.dom.classes.enable goog.dom.getElement('frown'), 'active', song.isFrown

    VU::_addLink = (elm, callback) ->
        goog.events.removeAll elm
        goog.events.listen elm, goog.events.EventType.CLICK, callback


    # Playback.


    VU::updatePlayback = (playback) ->
        @updatePlaybackTimes playback
        @updatePlaybackProgressbar playback
        @updatePlaybackOptions playback

    VU::updatePlaybackTimes = (playback) ->
        goog.dom.getElement('timeElapsed').textContent = @msToHumanTime playback.position
        goog.dom.getElement('timeDuration').textContent = @msToHumanTime playback.duration

    VU::updatePlaybackProgressbar = (playback) ->
        @progressbar.setValue playback.percentage

        progressbarElm = goog.dom.getElement 'progressbar'
        elapsedElm = goog.dom.getElementByClass 'elapsed', progressbarElm
        goog.style.setStyle elapsedElm, 'width': playback.percentage + '%'

    VU::updatePlaybackOptions = (playback) ->
        goog.dom.classes.set goog.dom.getElement('playpause'), if playback.status is 'PLAYING' then 'pause' else 'play'


    # Queue.


    VU::updateQueue = (queue) ->
        @updateQueueInformation queue
        @updateQueueSongs queue

    VU::updateQueueInformation = (queue) ->
        goog.dom.getElement('queuePosition').textContent = queue.activeSongIndex + 1
        goog.dom.getElement('queueCountSongs').textContent = queue.songs.length

    VU::updateQueueSongs = (queue) ->
        playlistElm = goog.dom.getElement('playlist')
        playlistElm.textContent = ''

        for song, index in queue.songs
            itemElm = goog.dom.createDom 'div',
                'class': 'item'
                textContent: song.artistName + ' - ' + song.songName
                onclick: @createOnclickActionForPlaylist song.queueSongId
            goog.dom.classes.enable itemElm, 'odd', index % 2 is 0
            goog.dom.classes.enable itemElm, 'active', song.queueSongId is queue.activeSongId
            goog.dom.appendChild playlistElm, itemElm

    VU::createOnclickActionForPlaylist = (queueSongId) ->
        -> gc.sendCommandToGrooveshark 'playSongInQueue', queueSongId: queueSongId


    # Autoplay.


    VU::updateAutoplay = (autoplay) ->
        autoplayTitle = chrome.i18n.getMessage if autoplay.enabled then 'radioOn' else 'radioOff'
        goog.dom.getElement('radioTitle').textContent = autoplayTitle


    # Misc.


    VU::msToHumanTime = (ms) ->
        s = ms / 1000
        minutes = parseInt s / 60
        seconds = parseInt s % 60
        if seconds < 10
            seconds = '0' + seconds
        minutes + ':' + seconds



    return
