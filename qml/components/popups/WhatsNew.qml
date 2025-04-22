import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: whatsNewPopup
    anchors.centerIn: Overlay.overlay

    width: 600
    height: 600

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside


    Label {
        id: titleLabel
        text: "What's New"
        font.pixelSize: 24
        font.bold: true
        horizontalAlignment: Text.AlignHCenter 
        anchors.top: parent.top
        height: 50
    }


    Button {
        text: "Close"
        anchors.right: parent.right
        anchors.bottomMargin: 50
        onClicked: whatsNewPopup.close()
    }

    ScrollView {
        id: scrollView
        anchors.top: titleLabel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        
        Flickable {
            id: flickableContainer
            contentWidth: parent.width - 20
            contentHeight: mainLayout.height + 20
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            ColumnLayout {
                id: mainLayout
                spacing: 15
                width: flickableContainer.width - 20

                GridLayout {
                    id: contentLayout
                    rowSpacing: 10
                    columnSpacing: 10
                    columns: 2

                    Label {
                        text: "1.0.0"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }

                    Label {
                        text: "First release of the application."
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        Layout.minimumWidth: 300
                    }

                    Label {
                        text: "1.0.1"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Bug fixes"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.0"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Layout improvements, removed sidebar"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.1"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Added Solkor Rf Calculator"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.2"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Added VR R+X Calculator, WaveCard blur"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.3"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Added Transformer OC calculator with cable 50, 51 50Q calculations"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.4"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Updates for many calculators fixing bugs and improving accurary of" +
                        " calculations. Added new calculator for CT & VT explaining naming convention"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        // horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.Wrap
                        Layout.alignment: Qt.AlignTop
                    }

                    Label {
                        text: "1.1.5"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Fix styling.  Improve logging.  Fix Wind & Grid calculations"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.6"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Improvements with loading calculators.  Performance improvements on Windows"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.7"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Added per unit impedance calculators"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.8"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Motor starting calculator improvements and bug fixes"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.1.9"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text: "Add DCM configurator.  Update file structure"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        text: "1.2.0"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignTop
                    }
                
                    Label {
                        text:   "Database overhaul and consolidation. Added export manager for common popups. " +
                                "Simplified image saving. Bug fixes for exporting in Voltage Drop Orion"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}