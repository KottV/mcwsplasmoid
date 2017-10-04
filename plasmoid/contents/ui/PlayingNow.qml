import QtQuick 2.8
import "../code/utils.js" as Utils

Item {
    readonly property bool isConnected: d.zoneCount > 0 & d.modelReady
    readonly property var model: pnModel
    readonly property alias timer: pnTimer
    readonly property alias hostUrl: reader.hostUrl

    readonly property var zoneModel: {
        var list = []
        for(var i=0; i<pnModel.count; ++i)
            list.push({ "zoneid": pnModel.get(i).zoneid, "zonename": pnModel.get(i).zonename })
        return list
    }

    QtObject{
        id: d
        property int zoneCount: 0
        property bool modelReady: false
        property int initCtr: 0
        property var currentVars: []

        function init() {
            zoneCount = 0
            initCtr = 0
            modelReady = false
            currentVars.length = 0
        }
    }

    signal connectionReady()
    signal trackChange(var zoneid, var filekey)
    signal totalTracksChange(var zoneid, var totalTracks)

    function run(cmd, zonendx) {
        if (zonendx === undefined)
            reader.exec(cmd)
        else {
            var delim = cmd.indexOf('?') === -1 ? '?' : '&'
            reader.exec("%1%2Zone=%3".arg(cmd).arg(delim).arg(pnModel.get(zonendx).zoneid))
            event.singleShot(300, function(){ updateModelItem(zonendx) })
        }
    }

    function zonesByStatus(status) {
        var list = []
        for(var i=0; i<pnModel.count; ++i) {
            if (pnModel.get(i).status === status)
                list.push(i)
        }
        return list
    }
    function imageUrl(filekey, size) {
        var imgsize = (size === undefined | size === null) ? 'medium' : size
        return hostUrl + "File/GetImage?Thumbnailsize=" + imgsize + "&File=" + filekey
    }

    function updateModel(status, include) {
        var inclStatus = (include === undefined || include === null) ? true : include

        if (inclStatus) {
            for (var z=0; z<pnModel.count; ++z) {
                if (pnModel.get(z).status === status) {
                    updateModelItem(z)
                }
            }
        }
        else {
            for (var z=0; z<pnModel.count; ++z) {
                if (pnModel.get(z).status !== status) {
                    updateModelItem(z)
                }
            }
        }
    }
    function updateModelItem(ndx) {
        // reset some transient fields
        pnModel.setProperty(ndx, "linkedzones", "")
        // pass model/ndx so the reader will update it directly
        reader.runQuery("Playback/Info?zone=" + pnModel.get(ndx).zoneid, pnModel, ndx)
    }
    function init(host) {
        // clean up
        pnTimer.stop()
        pnModel.clear()
        d.init()
        reader.currentHost = host
        // Set callback to get zones, reset when done to prepare reader for pn poller
        reader.callback = function(data)
        {
            // seeding model entries
            d.zoneCount = data["numberzones"]
            for(var i = 0; i<d.zoneCount; ++i) {
                // playing now model, one "row" for each zone, roles filled in by the reader
                pnModel.append({"zoneid": data["zoneid"+i], "zonename": data["zonename"+i], "status": "Stopped", "linked": false})
                // keep up with changes to specific items for add'l signalling
                d.currentVars.push({"zoneid": data["zoneid"+i], "filekey": "", "playingnowtracks": "" })
            }
            updateModel("Playing", false)
            pnTimer.start()
            reader.callback = null
        }
        reader.runQuery("Playback/Zones")
    }

    function playPlaylist(plid, zonendx) {
        run("Playlist/Files?Shuffle=1&Action=Play&Playlist=" + plid, zonendx)
    }
    function addPlaylist(plid, zonendx) {
        run("Playlist/Files?Shuffle=1&Action=Play&PlayMode=Add&Playlist=" + plid, zonendx)
    }
    function play(zonendx) {
        run("Playback/PlayPause", zonendx)
    }
    function previous(zonendx) {
        run("Playback/Previous", zonendx)
    }
    function next(zonendx) {
        run("Playback/Next", zonendx)
    }
    function stop(zonendx) {
        run("Playback/Stop", zonendx)
    }
    function stopAllZones() {
        run("Playback/StopAll")
    }

    function unLinkZone(zonendx) {
        run("Playback/UnlinkZones", zonendx)
    }
    function linkZones(zone1id, zone2id) {
//        pnTimer.stop()
        run("Playback/LinkZones?Zone1=" + zone1id + "&Zone2=" + zone2id)
//        event.singleShot(1000, function()
//        {
//            updateModel("Playing", false)
//            pnTimer.start()
//        })
    }

    function toggleMute(zonendx) {
        run("Playback/Volume?Level=%1".arg(pnModel.get(zonendx).volume === "0" ? "1" : "0"), zonendx)
    }
    function setVolume(level, zonendx) {
        run("Playback/Volume?Level=" + level, zonendx)
    }

    function shuffle(zonendx) {
        run("Playback/Shuffle?Mode=reshuffle", zonendx)
        event.singleShot(250, function()
        {
            var obj = pnModel.get(zonendx)
            totalTracksChange(obj.zoneid, obj.playingnowtracks)
        })
    }

    function removeTrack(trackndx, zonendx) {
        run("Playback/EditPlaylist?Action=Remove&Source=" + trackndx, zonendx);
    }
    function clearPlaylist(zonendx) {
        run("Playback/ClearPlaylist", zonendx);
    }
    function playTrack(pos, zonendx) {
        run("Playback/PlaybyIndex?Index=" + pos, zonendx);
    }
    function setPlayingPosition(pos, zonendx) {
        run("Playback/Position?Position=" + pos, zonendx)
    }

    SingleShot {
        id: event
    }

    Reader {
        id: reader
        onDataReady: {
//            if (data["index"] === undefined)
//                console.log(Utils.stringList(data))

            // special case addition for linked indicator
            pnModel.setProperty(data["index"], "linked", data["linkedzones"] === undefined ? false : true)
            // check for some common changes
            var keycheck = data["filekey"]
            var trackscheck = data["playingnowtracks"]
            var currCheck = d.currentVars[data["index"]]  // index in the data === index in the currentVars obj

            if (currCheck.filekey !== keycheck) {
                currCheck.filekey = keycheck
                trackChange(data["zoneid"], keycheck)
            }
            if (currCheck.playingnowtracks !== trackscheck) {
                currCheck.playingnowtracks = trackscheck
                totalTracksChange(data["zoneid"], trackscheck)
            }

            // tell consumers models are ready
            if (!d.modelReady) {
                d.initCtr++
                if (d.zoneCount === d.initCtr) {
                    d.modelReady = true
                    connectionReady()
                }
            }
        }
    }

    ListModel {
        id: pnModel
    }

    Timer {
        id: pnTimer; repeat: true
        triggeredOnStart: true

        property int ctr: 0
        onTriggered: {
            ++ctr
            if (ctr === 5) {
                ctr = 0
                updateModel("Playing", false)
            }
            updateModel("Playing")
        }

    }

}
