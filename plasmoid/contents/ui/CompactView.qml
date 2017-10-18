import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls

import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
        anchors.fill: parent

        SingleShot {
            id: event
        }

        ListView {
            id: lvCompact
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: 3
            delegate: RowLayout {
                spacing: 1

                Rectangle {
                    id: stateInd
                    implicitHeight: units.gridUnit*.5
                    implicitWidth: units.gridUnit*.5
                    Layout.margins: 3
                    radius: 5
                    color: model.state !== mcws.stateStopped ? "light green" : "grey"
                    NumberAnimation {
                        running: model.state === mcws.statePaused
                        target: stateInd
                        properties: "opacity"
                        from: 1
                        to: 0
                        duration: 1500
                        loops: Animation.Infinite
                        onStopped: stateInd.opacity = 1
                      }
                }
                PlasmaComponents.Label {
                    id: txt

                    property string aText: name + "\n" + artist

                    Layout.fillWidth: true
                    font.pointSize: theme.defaultFont.pointSize-1.5
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            clickedFromTray = index
                            plasmoid.expanded = !plasmoid.expanded
                        }
                    }
                    onATextChanged: event.singleShot(100, function(){ seq.start() })
                    SequentialAnimation {
                        id: seq
                            NumberAnimation { target: txt; property: "opacity"; to: 0; duration: 500 }
                            PropertyAction { target: txt; property: "text"; value: txt.aText }
                            NumberAnimation { target: txt; property: "opacity"; to: 1; duration: 500 }
                    }
                }
                PlasmaComponents.ToolButton {
                    iconSource: "media-skip-backward"
                    flat: false
                    visible: mcws.isConnected
                    enabled: playingnowposition !== "0"
                    onClicked: mcws.previous(index)
                }
                PlasmaComponents.ToolButton {
                    iconSource: {
                        if (mcws.isConnected)
                            model.state === mcws.statePlaying ? "media-playback-pause" : "media-playback-start"
                        else
                            "media-playback-start"
                    }
                    flat: false
                    visible: mcws.isConnected
                    onClicked: mcws.play(index)
                }
                PlasmaComponents.ToolButton {
                    iconSource: "media-skip-forward"
                    flat: false
                    visible: mcws.isConnected
                    enabled: nextfilekey !== "-1"
                    onClicked: mcws.next(index)
                }
            }
        }

        PlasmaComponents.Button {
            text: "MCWS Remote (click here to connect)"
            visible: currentZone === -1
            onClicked: {
                plasmoid.expanded = !plasmoid.expanded
                event.singleShot(500, function()
                {
                    lvCompact.model = mcws.model
                    lvCompact.positionViewAtIndex(currentZone, ListView.End)
                })
            }
        }
}
