import QtQuick 2.8
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Item {
    height: 32
    width: height

    property bool animateLoad: false

    Image {
        id: img

        property var aSource: mcws.imageUrl(filekey)

        onASourceChanged: {
            if (animateLoad)
                Qt.callLater(function(){ seq.start() })
            else
                source = aSource
        }

        sourceSize.height: parent.height
        sourceSize.width: parent.width
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 2
            verticalOffset: 2
            color: "#80000000"
        }

        SequentialAnimation {
            id: seq
            NumberAnimation { target: img; property: "opacity"; to: 0; duration: 500 }
            PropertyAction { target: img; property: "source"; value: img.aSource }
            NumberAnimation { target: img; property: "opacity"; to: .8; duration: 500 }
        }

        onStatusChanged: {
            if (status === Image.Error) {
                source = 'default.png'
                mcws.setImageError(filekey)
            }
        }
    }
}
