import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var expanded: {detailed}
    width: sideBar.width

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

                delegate: ItemDelegate {
                    implicitHeight: 60
                    
                    highlighted: ListView.isCurrentItem
                    anchors.horizontalCenter:parent.horizontalCenter

                    icon.name: model.icon
                    icon.width: 60
                    icon.height: 60

                    onClicked: {
                        if (listView.currentIndex == index && detailed.state == 'open') {
                            detailed.state = 'close'
                        } else {
                            detailed.state = 'open'
                            stackView.push(model.source,StackView.Immediate)
                        }
                        listView.currentIndex = index
                        detailed.currentIndex = index
                    }
                }

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

                footer:
                    ItemDelegate {
                        id: footerdel
                        anchors.horizontalCenter:parent.horizontalCenter
                        highlighted: listView.currentIndex == -1
                        implicitHeight: 60

                        icon.name: 'Setting'
                        icon.width: 60
                        icon.height: 60

                        onClicked: {
                            if (listView.currentIndex == -1 && detailed.state == 'open') {
                                detailed.state = 'close'
                            } else if (footerdel.highlighted == true && detailed.state == 'close') {
                                detailed.state = 'open'
                                
                            } else {
                                detailed.state = 'open'
                                stackView.push("../pages/settings.qml")
                            }
                            listView.currentIndex = -1
                            detailed.currentIndex = -1
                            
                        }
                    }
            }

            ListView {
                id: detailed
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                Layout.leftMargin: -5
                clip: true

                footerPositioning : ListView.OverlayFooter

                currentIndex: 0

                state: 'close'

                transitions: [
                    Transition {
                        from: 'close'
                        to: 'open'

                        NumberAnimation {
                            properties: "Layout.preferredWidth,x,y,opacity"
                            easing.type: Easing.InOutQuad
                            duration: 250
                            }
                        NumberAnimation {
                            properties: "visible"
                            easing.type: Easing.InOutQuad
                            duration: 100
                            }
                    },
                    Transition {
                        from: 'open'
                        to: 'close'

                        NumberAnimation {
                            properties: "Layout.preferredWidth,x,y,opacity"
                            easing.type: Easing.InOutQuad
                            duration: 250
                            }

                        NumberAnimation {
                            properties: "visible"
                            easing.type: Easing.InOutQuad
                            duration: 350
                            }
                    }
                ]

                states: [
                    State {
                        name: 'open'
                            PropertyChanges {
                                target: detailed
                                Layout.preferredWidth: 120
                                x: 60
                                y: 0
                                visible: true
                                opacity: 1
                            }
                        },
                    State {
                        name: 'close'
                            PropertyChanges {
                                target: detailed
                                Layout.preferredWidth: 0
                                x: -100
                                y: 0
                                visible: false
                                opacity: 0
                            }
                        }
                    ]

                delegate: ItemDelegate {
                    width:120
                    height: 60
                    text: model.title
                    highlighted: ListView.isCurrentItem

                    onClicked: {
                        if (listView.currentIndex == index && detailed.state == 'open') {
                                detailed.state = 'close'
                        } else {
                            detailed.state = 'open'
                            stackView.push(model.source)

                        }
                        listView.currentIndex = index
                        detailed.currentIndex = index
                    }
                }

                model: ListModel {
                    ListElement {
                        title: 'Home'
                        source: "../pages/home.qml"
                        tooltip: "Home"
                        }
                    ListElement {
                        title: 'Voltage Drop'
                        source: "../pages/voltage_drop.qml"
                        tooltip: "Voltage Drop"
                    }
                }
                footer:
                    ItemDelegate {
                        width:120
                        height: 60
                        
                        highlighted: listView.currentIndex == -1
                        anchors.horizontalCenter:parent.horizontalCenter
                        text: "Settings"

                        onClicked: {
                            if (listView.currentIndex == -1 && detailed.state == 'open') {
                                detailed.state = 'close'
                            } else {
                                detailed.state = 'open'
                                stackView.push("../pages/settings.qml")
                            }
                            listView.currentIndex = -1
                            detailed.currentIndex = -1
                        }
                    }
            }
        }
    }
}