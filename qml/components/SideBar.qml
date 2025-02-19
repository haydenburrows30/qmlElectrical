import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Drawer {
    id: sideBar
    // width automatically derived from RowLayout child's implicitWidth
    height: parent.height
    property int position1: {sideBar.position}

    function react() {
        if (sideBar.position == 0) {
            sideBar.open()
            stackView.anchors.leftMargin = sideBar.width + 5
        }
        else {
            stackView.anchors.leftMargin = 0
            sideBar.close()
        }
    }

    function closey() {
        stackView.anchors.leftMargin = 0
        sideBar.close()
    }

    modal: false
    interactive: false

    RowLayout {
        id: rowLayout
        height: parent.height

        Layout.alignment: Qt.AlignHCenter

        ListView {
            id: listView
            currentIndex: 0
            Layout.preferredWidth: 160
            Layout.fillHeight: true

            clip: true
            footerPositioning : ListView.OverlayFooter

            delegate: 
                ItemDelegate {
                    implicitHeight: 60
                    implicitWidth: 160
                    text: model.title

                    highlighted: ListView.isCurrentItem

                    icon.name: model.icon
                    icon.width: 30
                    icon.height: 30

                    onClicked: {
                        stackView.push(model.source,StackView.Immediate)
                        listView.currentIndex = index
                    }
                }

            model: ListModel {
                ListElement {
                    title: "Home"
                    source: "../pages/home.qml"
                    tooltip: "Home"
                    icon: "Home"
                    }
                ListElement {
                    title: "Voltage Drop"
                    source: "../pages/voltage_drop.qml"
                    tooltip: "Voltage Drop"
                    icon: "Voltage Drop"
                }
                // ListElement {
                //     source: "../pages/Perceptron.qml"
                //     tooltip: "Perceptron"
                //     icon: "Voltage Drop"
                // }
            }

            footer:
                ItemDelegate {
                    id: footerdel
                    highlighted: listView.currentIndex == -1
                    implicitHeight: 60
                    implicitWidth: 160
                    text: "Settings"
                    
                    icon.name: 'Setting'
                    icon.width: 30
                    icon.height: 30

                    onClicked: {
                        stackView.push("../pages/settings.qml", StackView.Immediate)
                        listView.currentIndex = -1
                    }
                }
        }
    }
}