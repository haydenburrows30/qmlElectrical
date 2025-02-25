import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Drawer {
    id: sideBar
    // width automatically derived from RowLayout child's implicitWidth
    height: parent.height
    property int position1: {sideBar.position}
    property int hide: 0
    property int show: 0

    onAboutToHide: {
        show = 0
        hide = 1
    }

    onAboutToShow: {
        hide = 0
        show = 1
    }

    function react() {
        if (sideBar.position == 0) {
            sideBar.open()
        }
        else {
            sideBar.close()
        }
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
                ListElement {
                    title: "Calculator"
                    source: "../pages/calculator.qml"
                    tooltip: "Calculator"
                    icon: "Calculator"
                }
            }

            // footer:
            //     ItemDelegate {
            //         id: footerdel
            //         highlighted: listView.currentIndex == -1
            //         implicitHeight: 60
            //         implicitWidth: 160
            //         text: "Settings"
                    
            //         icon.name: 'Setting'
            //         icon.width: 30
            //         icon.height: 30

            //         onClicked: {
            //             stackView.push("../pages/settings.qml", StackView.Immediate)
            //             listView.currentIndex = -1
            //         }
            //     }
        }
    }
}