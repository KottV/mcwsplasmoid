import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3 as QtControls
import org.kde.plasma.components 2.0 as PlasmaComponents

RowLayout {
    property bool showLabel: true
    property bool showSlider: true

    PlasmaComponents.Label {
        visible: showLabel
        text: "Track " + playingnowpositiondisplay

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            QtControls.ToolTip.visible: containsMouse && model.state === mcws.statePlaying
            QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            QtControls.ToolTip.text: audiopath
        }
    }

    QtControls.Slider {
        id: trackPos
        visible: showSlider
        from: 0
        to: durationms / 10000
        value: positionms / 10000

        onMoved: {
            if (!posTimer.running) {
                posTimer.start()
                trackPos.state = 'moving'
            }
            posTimer.ndx = index
            posTimer.val = position*to*10000
        }

        states: [
            State {
                name: 'moving'
                PropertyChanges { target: trackPos; value: null }
            }
        ]

        background: Rectangle {
            id: sliderRect
            x: trackPos.leftPadding
            y: trackPos.topPadding + trackPos.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 4
            width: trackPos.availableWidth
            height: implicitHeight
            radius: 2

            Rectangle {
                width: trackPos.visualPosition * parent.width
                height: parent.height
                color: "dark grey"
                radius: 2
            }
        }
        handle: Rectangle {
            x: trackPos.leftPadding + trackPos.visualPosition * (trackPos.availableWidth - width)
            y: trackPos.topPadding + trackPos.availableHeight / 2 - height / 2
            implicitWidth: 15
            implicitHeight: 15
            radius: 13
            color: trackPos.pressed ? "#f0f0f0" : "#f6f6f6"
            border.color: "#bdbebf"
        }
    }

    Timer {
        id: posTimer
        repeat: true
        interval: 100

        property int val
        property int ndx

        onTriggered: {
            if (!trackPos.pressed) {
                stop()
                mcws.setPlayingPosition(ndx, val)
                event.queueCall(500, function() { trackPos.state = '' })
            }
        }
    }
}
