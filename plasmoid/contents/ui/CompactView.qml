import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import QtGraphicalEffects 1.0
import "controls"

Item {
    id: root
    anchors.fill: parent

    property int txtMaxSize: (width / mcws.zoneModel.count) * multi
    property int pixSize: root.height * 0.2
    property real multi: (pixSize > theme.mSize(theme.defaultFont).width * 1.5)
                            ? (pixSize / theme.mSize(theme.defaultFont).width)
                            : 1

//    onHeightChanged: console.log('width: ' + width + ' pixSize: ' + pixSize + ' ?>? ' + theme.mSize(theme.defaultFont).width * 1.5 + ' multi: ' + multi + ' txtMax: ' + txtMaxSize)

    function reset(zonendx) {

        var currZone = mcws.getPlayingZoneIndex()
        lvCompact.model = null
        event.singleShot(300, function()
        {
            lvCompact.model = mcws.zoneModel
            lvCompact.positionViewAtIndex(currZone, ListView.End)
            lvCompact.currentIndex = currZone
        })
    }

    signal zoneClicked(var zonendx)

    Connections {
        id: conn
        target: mcws
        enabled: false
        onConnectionReady: reset(zonendx)
    }

    DropShadow {
        anchors.fill: lvCompact
        radius: 3
        samples: 7
        visible: plasmoid.configuration.dropShadows
        color: theme.backgroundColor
        source: lvCompact
    }

    ListView {
        id: lvCompact
        anchors.fill: parent
        orientation: ListView.Horizontal

        property int hoveredInto: -1

        function itemClicked(ndx, pnTracks) {
            if (pnTracks !== 0) {
                lvCompact.hoveredInto = -1
                lvCompact.currentIndex = ndx
            }
            zoneClicked(ndx)
        }

        Component {
            id: rectComp
            Rectangle {
                implicitHeight: units.gridUnit*.5
                implicitWidth: implicitHeight
                radius: 5
                color: "light green"
            }
        }
        Component {
            id: imgComp
            TrackImage {
                animateLoad: true
                implicitHeight: root.height * .75
                implicitWidth: implicitHeight
                sourceKey: filekey
            }
        }

        delegate: RowLayout {
            id: compactDel
            spacing: 1
            // spacer
            Rectangle {
                Layout.rightMargin: 3
                Layout.leftMargin: 3
                Layout.alignment: Qt.AlignCenter
                width: 1
                height: root.height
                color: "grey"
                opacity: index > 0
            }
            // playback indicator
            Loader {
                id: indLoader
                sourceComponent: model.state !== mcws.stateStopped
                                 ? (plasmoid.configuration.useImageIndicator ? imgComp : rectComp)
                                 : undefined

                // TrackImage (above) uses filekey, so propogate it to the component
                property string filekey: model.filekey

                Layout.rightMargin: 3
                width: units.gridUnit * (plasmoid.configuration.useImageIndicator ? 1.75 : .5)
                height: width
                visible: model.state !== mcws.stateStopped

                MouseArea {
                    anchors.fill: parent
                    onClicked: lvCompact.itemClicked(index, +playingnowtracks)
                }

                OpacityAnimator {
                    running: model.state === mcws.statePaused
                    target: indLoader
                    from: 1
                    to: 0
                    duration: 1500
                    loops: Animation.Infinite
                    onStopped: indLoader.opacity = 1
                }
            }
            // track text
            ColumnLayout {
                spacing: 0
                FadeText {
                    aText: +playingnowtracks > 0 ? name : zonename
                    font.pointSize: pixSize
                    anchors.right: parent.right
                    Layout.maximumWidth: txtMaxSize
                    elide: Text.ElideRight
                }
                FadeText {
                    aText: +playingnowtracks > 0 ? artist : trackdisplay
                    font.pointSize: pixSize
                    anchors.right: parent.right
                    Layout.maximumWidth: txtMaxSize
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        if (+playingnowtracks === 0)
                            return

                        lvCompact.hoveredInto = index
                        event.singleShot(700, function()
                        {
                            if (lvCompact.hoveredInto === index)
                                lvCompact.currentIndex = index
                        })
                    }
                    onExited: lvCompact.hoveredInto = -1
                    onClicked: lvCompact.itemClicked(index, +playingnowtracks)
                }
            }
            // playback controls
            PrevButton {
                Layout.leftMargin: 3
                opacity: compactDel.ListView.isCurrentItem
                visible: opacity
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
            }
            PlayPauseButton {
                opacity: compactDel.ListView.isCurrentItem
                visible: opacity
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
            }
            StopButton {
                opacity: compactDel.ListView.isCurrentItem
                visible: plasmoid.configuration.showStopButton && opacity
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
            }
            NextButton {
                opacity: compactDel.ListView.isCurrentItem
                visible: opacity
                Behavior on opacity {
                    NumberAnimation { duration: 750 }
                }
            }
        }
    }

    Component.onCompleted: {
        if (mcws.isConnected) {
            reset(clickedZone)
        }
        // bit of a hack to deal with the dynamic loader as form factor changes vs. plasmoid startup
        // event-queue the connection-enable on startup
        Qt.callLater(function(){ conn.enabled = true })
    }
}
