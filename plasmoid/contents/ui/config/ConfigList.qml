import QtQuick 2.9
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents

ColumnLayout {
    id: cfgList

    property var items: []
    property string configKey: ''
    property alias placeHolder: txtField.placeholderText
    property alias newText: txtField.text
    property alias showInputField: layout.visible

    Component.onCompleted: load()

    signal itemClicked(var item)
    signal configChanged()

    function load() {
        items = plasmoid.configuration[configKey]
        txtField.forceActiveFocus()
        lv.model = items
    }

    function addItem(str) {
        if (str !== '') {
            items.push(str)
            lv.model = items
            configChanged()
        }
    }

    function removeItem(index) {
        items.splice(index, 1)
        lv.model = items
        configChanged()
    }
    function moveItem(from,to) {
        var tmp = items[to]
        items[to] = items[from]
        items[from] = tmp
        lv.model = items
        configChanged()
    }

    RowLayout {
        id: layout
        Layout.fillWidth: true
        width: parent.width

        PlasmaComponents.TextField {
            id: txtField
            Layout.fillWidth: true
            onAccepted: addItem.clicked()
        }

        PlasmaComponents.ToolButton {
            id: add
            iconName: "list-add"
            enabled: txtField.text.length > 0
            onClicked: {
                addItem(txtField.text)
                txtField.text = ""
                txtField.forceActiveFocus()
            }
        }
    }

    ListView {
        id: lv
        Layout.fillHeight: true
        Layout.fillWidth: true
        clip: true
        delegate: RowLayout {
            width: parent.width

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: modelData
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        txtField.text = modelData
                        cfgList.itemClicked(modelData)
                    }
                }
            }

            PlasmaComponents.ToolButton {
                iconName: "arrow-up"
                enabled: index !== 0
                onClicked: moveItem(index, index-1)
            }
            PlasmaComponents.ToolButton {
                iconName: "arrow-down"
                enabled: index !== items.length-1
                onClicked: moveItem(index, index+1)
            }
            PlasmaComponents.ToolButton {
                iconName: "list-remove"
                onClicked: removeItem(index)
            }
        }
    }
}
