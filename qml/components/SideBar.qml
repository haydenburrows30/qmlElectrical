import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Drawer {
    id: sideBar
    // width automatically derived from RowLayout child's implicitWidth
    height: parent.height
    width: 60
    property int open_closed: {sideBar.position}
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

    function change(indexchange) {
        listView.currentIndex = indexchange
    }

    modal: false
    interactive: false
    visible: true

    Rectangle {
        id:fade
        width: parent.width
        anchors.top: parent.top
        height: 20
        z:99
        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop { position: 1.0; color: "transparent" }
            GradientStop { position: 0; color: palette.base }
        }
    }

    RowLayout {
        id: rowLayout
        height: parent.height - 10

        Layout.alignment: Qt.AlignHCenter

        ListView {
            id: listView
            currentIndex: 0
            Layout.preferredWidth: 60
            Layout.fillHeight: true

            clip: true
            footerPositioning : ListView.OverlayFooter

            delegate: 
                ItemDelegate {
                    implicitHeight: 60
                    implicitWidth: 60

                    highlighted: ListView.isCurrentItem

                    icon.name: model.icon
                    icon.width: 30
                    icon.height: 30

                    CToolTip {
                        id: toolTip
                        text: model.title
                        width: 110
                    }

                    onClicked: {
                        stackView.push(model.source,StackView.Immediate)
                        listView.currentIndex = index
                        toolTip.close()
                    }
                }

            model: ListModel {
                ListElement {
                    title: "Home"
                    source: "../pages/Home.qml"
                    tooltip: "Home"
                    icon: "Home"
                    }
                ListElement {
                    title: "Voltage Drop"
                    source: "../pages/VoltageDrop.qml"
                    tooltip: "Voltage Drop"
                    icon: "Voltage Drop"
                }
                ListElement {
                    title: "Calculator"
                    source: "../pages/Calculator.qml"
                    tooltip: "Calculator"
                    icon: "Calculator"
                }
                ListElement {
                    title: "Three Phase"
                    source: "../pages/ThreePhase.qml"
                    tooltip: "Three Phase"
                    icon: "Wave"
                }
                ListElement {
                    title: "Phasor"
                    source: "../pages/Phasor.qml"
                    tooltip: "RLC"
                    icon: "RLC"
                }
                ListElement {
                    title: "Phasor"
                    source: "../pages/VoltageDropMV.qml"
                    tooltip: "RLC"
                    icon: "RLC"
                }
            }

            footer:
                ItemDelegate {
                    id: footerdel
                    highlighted: listView.currentIndex == -1
                    implicitHeight: 60
                    implicitWidth: 60

                    CToolTip {
                        id: toolTip
                        text: "Settings"
                        width: 110
                    }
                    
                    icon.name: 'Setting'
                    icon.width: 30
                    icon.height: 30

                    onClicked: {
                        settings.open()
                        listView.currentIndex = -1
                    }
                }
        }
    }
}