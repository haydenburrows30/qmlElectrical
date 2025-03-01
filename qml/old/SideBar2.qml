import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    focus: true

    property var expanded: {detailed}
    property var sideBar: sideBar
    // width: sideBar.width

    MouseArea {
            anchors.fill: parent
            onClicked:  {
                if (sideBar.expanded.state == 'open') {
                            sideBar.expanded.state = 'close'
                    }
            }

            onEntered: {
                console.log("entered")
            }
        }

    Drawer {
        id: sideBar
        // width automatically derived from RowLayout child's implicitWidth
        height: parent.height

        Component.onCompleted: {
            sideBar.open()
        }

        modal: false
        interactive: false

        RowLayout {
            id: rowLayout
            height: parent.height

            ListView {
                id: listView
                // focus: true
                currentIndex: 0
                Layout.preferredWidth: 60
                Layout.fillHeight: true
                clip: true
                footerPositioning : ListView.OverlayFooter

                model: ListModel {
                    ListElement {
                        source: "../pages/home.qml"
                        tooltip: "Home"
                        icon: "Home"
                        }
                    ListElement {
                        source: "../pages/voltage_drop.qml"
                        tooltip: "Voltage Drop"
                        icon: "Voltage Drop"
                    }
                }

                delegate: ItemDelegate {
                    id: control
                    implicitHeight: 60

                    highlighted: ListView.isCurrentItem
                    anchors.horizontalCenter:parent.horizontalCenter

                    icon.name: model.icon
                    icon.width: 60
                    icon.height: 60

                    CToolTip {}

                    onClicked: {
                        // detailed.state = 'open'
                        detailed.x = 120
                        detailed.y = 120
                        stackView.push(model.source,StackView.Immediate)
                        listView.currentIndex = index
                        // detailed.currentIndex = index
                    }
                } 
            }
        }
    }
}


// Rectangle {
//         id: detailed
//         width: 120
//         height: 60
//         // anchors.left: sideBar.right
//         z:99
//         // Layout.fillHeight: true
//         color: "red"
//         visible: sideBar.sideBar

//         state: 'close'

//         transitions: [
//             Transition {
//                 from: 'close'
//                 to: 'open'

//                 NumberAnimation {
//                     properties: "Layout.preferredWidth,x,y,opacity"
//                     easing.type: Easing.InOutQuad
//                     duration: 250
//                     }
//                 NumberAnimation {
//                     properties: "visible"
//                     easing.type: Easing.InOutQuad
//                     duration: 100
//                     }
//             },
//             Transition {
//                 from: 'open'
//                 to: 'close'

//                 NumberAnimation {
//                     properties: "Layout.preferredWidth,x,y,opacity"
//                     easing.type: Easing.InOutQuad
//                     duration: 250
//                     }

//                 NumberAnimation {
//                     properties: "visible"
//                     easing.type: Easing.InOutQuad
//                     duration: 350
//                     }
//             }
//         ]

//         states: [
//             State {
//                 name: 'open'
//                     PropertyChanges {
//                         target: detailed
//                         // Layout.preferredWidth: 120
//                         x: 60
//                         y: 120
//                         visible: true
//                         opacity: 1
//                     }
//             },
//             State {
//                 name: 'close'
//                     PropertyChanges {
//                         target: detailed
//                         // Layout.preferredWidth: 0
//                         x: -100
//                         y: 0
//                         visible: true
//                         opacity: 0
//                     }
//             }
//         ]
//     }