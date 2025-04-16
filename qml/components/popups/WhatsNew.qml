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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        Label {
            text: "What's New"
            font.pixelSize: 24
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            GridLayout {
                id: contentLayout
                anchors.fill: parent

                columns: 2

                Label {
                    text: "1.0.0"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            
                Label {
                    text: "First release of the application."
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }

                Label {
                    text: "1.0.1"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
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
                }
            
                Label {
                    text: "Updates for many calculators fixing bugs and improving accurary of" +
                    " calculations. Added new calculator for CT & VT explaining naming convention"
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }

                Label {
                    text: "1.1.5"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
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
                }
            
                Label {
                    text: "Added per unit impedance calculators"
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
        
        Button {
            text: "Close"
            Layout.alignment: Qt.AlignHCenter
            onClicked: whatsNewPopup.close()
        }
    }
}