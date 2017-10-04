import QtQuick 2.8
import QtQuick.Controls 2.2
import org.kde.plasma.plasmoid 2.0

ListView {
    id: listView

    function getObj() {
        return model.get(currentIndex)
    }

    add: Transition {
             NumberAnimation { properties: "x,y"; from: 100; duration: 800 }
         }
    populate: Transition {
              NumberAnimation { properties: "x,y"; duration: 800 }
          }
    anchors.fill: parent
    spacing: 6
    clip: true
    highlightMoveDuration: 1
    highlight: Rectangle {
        width: listView.width
        color: plasmoid.configuration.highlightColor
        radius: 5
        y: listView.currentItem.y
        Behavior on y {
            SpringAnimation {
                spring: 3
                damping: 0.2
            }
        }
    }
    Component.onCompleted: currentIndex = -1
}
