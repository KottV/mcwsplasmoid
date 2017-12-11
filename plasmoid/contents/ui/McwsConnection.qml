import QtQuick 2.8
import "../code/utils.js" as Utils
import "models"

Item {
    readonly property bool isConnected: (d.zoneCount > 0) && d.modelReady
    property ListModel zoneModel: ListModel{}
    readonly property var playlists: playlists
    readonly property alias hostUrl: reader.hostUrl

    property alias pollerInterval: pnTimer.interval
    onPollerIntervalChanged: pnTimer.restart()

    // Player states
    readonly property string stateStopped:  "0"
    readonly property string statePaused:   "1"
    readonly property string statePlaying:  "2"
    readonly property string stateAborting: "3"
    readonly property string stateBuffering:"4"

    // private stuff
    QtObject{
        id: d

        property int zoneCount: 0
        property int currZoneIndex: 0
        property bool modelReady: false
        property int initCtr: 0

        function init(host) {
            pnTimer.stop()
            zoneModel.clear()
            playlists.clear()
            zoneCount = 0
            currZoneIndex = 0
            initCtr = 0
            modelReady = false
            reader.currentHost = host
        }

        function loadRepeatMode(zonendx) {
            dynReader.runQuery("Playback/Repeat?ZoneType=Index&Zone=" + zonendx
                 , function(data)
                 {
                     zoneModel.set(zonendx, {"repeat": data["mode"]})
                 })
        }
    }

    signal connectionReady(var zonendx)
    signal trackKeyChanged(var zonendx, var trackKey)

    function forEachZone(func) {
        if (func === undefined | typeof(func) !== 'function')
            return

        for (var i=0, len = zoneModel.count; i < len; ++i)
            func(mcws.zoneModel.get(i), i)
    }

    function run(zonendx, cmd) {
        if (zonendx === undefined | zonendx === -1)
            reader.exec(cmd)
        else {
            var delim = cmd.indexOf('?') === -1 ? '?' : '&'
            reader.exec("%1%2Zone=%3".arg(cmd).arg(delim).arg(zoneModel.get(zonendx).zoneid))
            event.singleShot(300, function(){ updateModelItem(zonendx) })
        }
    }

    function zonesByState(state) {
        var list = []
        forEachZone(function(zone, zonendx)
        {
            if (zone.state === state)
                list.push(zonendx)
        })

        return list
    }
    function imageUrl(filekey, size) {
        var imgsize = (size === undefined | size === null) ? 'medium' : size
        return hostUrl + "File/GetImage?Thumbnailsize=" + imgsize + "&File=" + filekey
    }

    function updateModel(state, include) {
        var inclStatus = (include === undefined || include === null) ? true : include

        if (inclStatus) {
            forEachZone(function(zone, zonendx)
            {
                if (zone.state === state)
                    updateModelItem(zonendx)
            })
        }
        else {
            forEachZone(function(zone, zonendx)
            {
                if (zone.state !== state)
                    updateModelItem(zonendx)
            })
        }
    }
    function updateModelItem(zonendx) {
        // reset some transient fields
        zoneModel.setProperty(zonendx, "linkedzones", "")
        // pass model/ndx so the reader will update it directly
        reader.runQuery("Playback/Info?zone=" + zoneModel.get(zonendx).zoneid, zoneModel, zonendx)
    }
    function connect(host) {
        // reset everything
        d.init(host)
        // Set callback to get zones, reset when done to prepare reader for pn poller
        reader.callback = function(data)
        {
            // seeding model entries
            d.zoneCount = data["numberzones"]
            d.currZoneIndex = data["currentzoneindex"]
            for(var i = 0; i<d.zoneCount; ++i) {
                // setup defined props in the model for each zone
                zoneModel.append({"zoneid": data["zoneid"+i]
                               , "zonename": data["zonename"+i]
                               , "state": stateStopped
                               , "linked": false
                               , "mute": false
                               , "prevfilekey": '-1'
                               })
                d.loadRepeatMode(i)
            }
            updateModel(statePlaying, false)
            pnTimer.start()
            reader.callback = null
        }
        reader.runQuery("Playback/Zones")
    }

    function play(zonendx) {
        run(zonendx, "Playback/PlayPause")
    }
    function previous(zonendx) {
        run(zonendx, "Playback/Previous")
    }
    function next(zonendx) {
        run(zonendx, "Playback/Next")
    }
    function stop(zonendx) {
        run(zonendx, "Playback/Stop")
    }
    function stopAllZones() {
        run(-1, "Playback/StopAll")
    }

    function unLinkZone(zonendx) {
        run(zonendx, "Playback/UnlinkZones")
    }
    function linkZones(zone1id, zone2id) {
        run(-1, "Playback/LinkZones?Zone1=" + zone1id + "&Zone2=" + zone2id)
    }

    function isPlaylistEmpty(zonendx) {
        return zoneModel.get(zonendx).playingnowtracks === '0'
    }
    function isStopped(zonendx) {
        return zoneModel.get(zonendx).state === stateStopped
    }
    function isPlaying(zonendx) {
        return zoneModel.get(zonendx).state === statePlaying
    }
    function isPaused(zonendx) {
        return zoneModel.get(zonendx).state === statePaused
    }

    function isMuted(zonendx) {
        return zoneModel.get(zonendx).mute
    }
    function toggleMute(zonendx) {
        setMute(zonendx, !isMuted(zonendx))
    }
    function setMute(zonendx, mute) {
        var val = (mute === undefined)
                ? "0"
                : mute ? "1" : "0"

        run(zonendx, "Playback/Mute?Set=" + val + "&ZoneType=Index")
    }
    function setVolume(zonendx, level) {
        run(zonendx, "Playback/Volume?Level=" + level)
    }

    function shuffle(zonendx) {
        run(zonendx, "Playback/Shuffle?Mode=reshuffle")
    }
    function setPlayingPosition(zonendx, pos) {
        run(zonendx, "Playback/Position?Position=" + pos)
    }
    function setRepeat(zonendx, mode) {
        run(zonendx, "Playback/Repeat?Mode=" + mode)
        event.singleShot(250, function() { d.loadRepeatMode(zonendx) })
    }
    function repeatMode(zonendx) {
        return zonendx >= 0 ? zoneModel.get(zonendx).repeat : ""
    }

    function removeTrack(zonendx, trackndx) {
        run(zonendx, "Playback/EditPlaylist?Action=Remove&Source=" + trackndx)
    }
    function clearPlaylist(zonendx) {
        run(zonendx, "Playback/ClearPlaylist")
    }
    function playTrack(zonendx, pos) {
        run(zonendx, "Playback/PlaybyIndex?Index=" + pos)
    }
    function playTrackByKey(zonendx, filekey) {
        var pos = +zoneModel.get(zonendx).playingnowposition + 1
        run(zonendx, "Playback/PlaybyKey?Key=%1&Location=%2".arg(filekey).arg(pos))
        event.singleShot(500, function() { playTrack(zonendx, pos) })
    }
    function addTrack(zonendx, filekey, next) {
        searchAndAdd(zonendx, "[key]=" + filekey, next, false)
    }

    function queueAlbum(zonendx, filekey, next) {
        run(zonendx, "Playback/PlaybyKey?Key=%1&Album=1&Location=%2".arg(filekey).arg(next ? "Next" : "End"))
    }
    function playAlbum(zonendx, filekey) {
        run(zonendx, "Playback/PlaybyKey?Album=1&Key=" + filekey)
    }
    function searchAndPlayNow(zonendx, srch, shuffleMode) {
        run(zonendx, "Files/Search?Action=Play&query=" + srch + (shuffleMode ? "&Shuffle=1" : ""))
    }
    function searchAndAdd(zonendx, srch, next, shuffleMode) {
        run(zonendx, "Files/Search?Action=Play&query=%1&PlayMode=%2".arg(srch).arg(next ? "NextToPlay" : "Add"))
        if (shuffleMode)
            event.singleShot(500, function() { shuffle(zonendx) })
    }

    function handleError(msg, cmd) {
        console.log("MCWS Error: " + msg + ": " + cmd)
    }

    SingleShot {
        id: event
    }

    Reader {
        id: reader
        onDataReady:
        {
            // handle defined props
            zoneModel.setProperty(index, "linked", data["linkedzones"] === undefined ? false : true)
            zoneModel.setProperty(index, "mute", data["volumedisplay"] === "Muted" ? true : false)

            // handle manual field changes
            if (data['filekey'] !== zoneModel.get(index).prevfilekey) {
                zoneModel.setProperty(index, 'prevfilekey', data['filekey'])
                trackKeyChanged(index, data['filekey'])
            }
            // tell consumers models are ready
            if (!d.modelReady) {
                d.initCtr++
                if (d.zoneCount === d.initCtr) {
                    d.modelReady = true
                    connectionReady(d.currZoneIndex)
                }
            }
        }
    }

    ReaderEx {
        id: dynReader
        currentHost: reader.currentHost
        onConnectionError: handleError
        onCommandError: handleError
    }

    Connections {
        target: reader
        onConnectionError: {
            handleError(msg, cmd)
            if (cmd.split('/')[2] === reader.currentHost)
                d.init("")
        }
        onCommandError: handleError(msg, cmd)
    }

    Playlists {
        id: playlists
        hostUrl: reader.hostUrl

        function play(plid, shuffleMode, zonendx) {
            run(zonendx, "Playlist/Files?Action=Play&Playlist=" + plid + (shuffleMode ? "&Shuffle=1" : ""))
        }
        function add(plid, shuffleMode, zonendx) {
            run(zonendx, "Playlist/Files?Action=Play&PlayMode=Add&Playlist=" + plid)
            if (shuffleMode)
                event.singleShot(500, function() { shuffle(zonendx) })
        }
    }

    Timer {
        id: pnTimer; repeat: true
        triggeredOnStart: true

        property int ctr: 0
        onTriggered: {
            ++ctr
            if (ctr === 3) {
                ctr = 0
                updateModel(statePlaying, false)
            }
            updateModel(statePlaying)
        }
    }
}
