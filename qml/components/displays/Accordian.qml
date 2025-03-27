import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../displays"
import "../style"

Pane {

    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentHeight: root.implicitHeight + 40
        contentWidth: parent.width
        clip: true

        Pane {
            id: root
            anchors.fill: parent

            Column {
                id: mainLayout
                anchors.right: parent.right
                anchors.left: parent.left

                RowLayout {

                    Button {
                        text: "Calculate Complete System"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 250
                        Layout.bottomMargin: 15
                        font.pixelSize: 14
                        onClicked: calculate()
                    }

                    Button {
                        text: "Close All"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 250
                        Layout.bottomMargin: 15
                        font.pixelSize: 14
                        onClicked: {
                            paneSettingsList.shown = false
                            paneSettingsList1.shown = false
                            paneSettingsList2.shown = false
                            paneSettingsList3.shown = false
                            paneSettingsList4.shown = false
                            paneSettingsList5.shown = false
                        }
                    }

                    Button {
                        text: "Open All"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 250
                        Layout.bottomMargin: 15
                        font.pixelSize: 14
                        onClicked: { 
                            paneSettingsList.shown = true
                            paneSettingsList1.shown = true
                            paneSettingsList2.shown = true
                            paneSettingsList3.shown = true
                            paneSettingsList4.shown = true
                            paneSettingsList5.shown = true
                        }
                    }
                }

                // LV Wind Generator Protection (400V)
                Column {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    property bool showList: false

                    Button {
                        id: button1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: "LV Wind Generator Protection (400V)"
                        onClicked: paneSettingsList.shown = !paneSettingsList.shown
                    }

                    Pane {
                        id: paneSettingsList

                        property bool shown: false
                        visible: height > 0
                        height: shown ? implicitHeight : 0
                        Behavior on height {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                            }
                        }

                        clip: true

                        padding: 0
                        anchors.left: parent.left
                        anchors.right: parent.right

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: Style.spacing

                            WindGenProtectionResults {}
                        }
                    }
                }

                //Line Protection
                Column {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    property bool showList: false

                    Button {
                        id: button2
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: "Line Protection (11kV)"
                        onClicked: paneSettingsList1.shown = !paneSettingsList1.shown
                        
                    }

                    Pane {
                        id: paneSettingsList1

                        property bool shown: false
                        visible: height > 0
                        height: shown ? implicitHeight : 0
                        Behavior on height {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                            }
                        }

                        clip: true

                        padding: 0
                        anchors.left: parent.left
                        anchors.right: parent.right

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: Style.spacing

                            LineProtectionResults {}
                        }
                    }
                }

                //Transformer Protection
                Column {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    property bool showList: false

                    Button {
                        id: button3
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: "Transformer Protection"
                        onClicked: paneSettingsList2.shown = !paneSettingsList2.shown
                        
                    }

                    Pane {
                        id: paneSettingsList2

                        property bool shown: false
                        visible: height > 0
                        height: shown ? implicitHeight : 0
                        Behavior on height {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                            }
                        }

                        clip: true

                        padding: 0
                        anchors.left: parent.left
                        anchors.right: parent.right

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: Style.spacing

                            ProtectionRequirementsResults {}
                        }
                    }
                }

                //Voltage Regulator 
                Column {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    property bool showList: false

                    Button {
                        id: button4
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: "Voltage Regulator Protection"
                        onClicked: paneSettingsList3.shown = !paneSettingsList3.shown
                        
                    }

                    Pane {
                        id: paneSettingsList3

                        property bool shown: false
                        visible: height > 0
                        height: shown ? implicitHeight : 0
                        Behavior on height {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                            }
                        }

                        clip: true

                        padding: 0
                        anchors.left: parent.left
                        anchors.right: parent.right

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: Style.spacing

                            VoltageRegResults {}
                        }
                    }
                }

                Column {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    property bool showList: false

                    Button {
                        id: button5
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: "ABB REF615"
                        onClicked: paneSettingsList4.shown = !paneSettingsList4.shown
                    }

                    Pane {
                        id: paneSettingsList4

                        property bool shown: false
                        visible: height > 0
                        height: shown ? implicitHeight : 0
                        Behavior on height {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                            }
                        }

                        clip: true

                        padding: 0
                        anchors.left: parent.left
                        anchors.right: parent.right

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: Style.spacing

                            ABBConfig {}
                        }
                    }
                }

                // Grid requirements
                Column {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    property bool showList: false

                    Button {
                        id: button6
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: "Grid Protection Requirements"
                        onClicked: paneSettingsList5.shown = !paneSettingsList5.shown
                        
                    }

                    Pane {
                        id: paneSettingsList5

                        property bool shown: false
                        visible: height > 0
                        height: shown ? implicitHeight : 0
                        Behavior on height {
                            NumberAnimation {
                                easing.type: Easing.InOutQuad
                            }
                        }

                        clip: true

                        padding: 0
                        anchors.left: parent.left
                        anchors.right: parent.right

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: Style.spacing

                            GridConnectionReq {}
                        }
                    }
                }
            }
        }
    }
}