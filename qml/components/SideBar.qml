import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var expanded: {detailed}
    width: sideBar.width

        MouseArea {
            anchors.fill: parent

            onClicked:  {
                if (sideBar.expanded.state == 'open') {
                            sideBar.expanded.state = 'close'
                    }
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
                
                delegate: ItemDelegate {
                    width: 60
                    height: 60
                    highlighted: ListView.isCurrentItem
                    icon.name: model.icon
                    icon.width: 30
                    icon.height: 30

                    onClicked: {
                        if (detailed.state == 'close') {
                                detailed.state = 'open'
                        }
                            // } else {
                            //     detailed.state = 'close'
                            // }
                        listView.currentIndex = index
                        detailed.currentIndex = index
                        stackView.push(model.source,StackView.Immediate)
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
            }

            ListView {
                id: detailed
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                Layout.leftMargin: -5
                currentIndex: 0
                visible: true

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
                        listView.currentIndex = index
                        detailed.currentIndex = index
                        stackView.push(model.source)
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
            }
        }
    }
}