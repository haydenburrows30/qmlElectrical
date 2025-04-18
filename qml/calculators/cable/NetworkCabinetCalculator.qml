import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import NetworkCabinetCalculator 1.0

Item {
    id: cabinetCalculator
    
    // Python backend calculator with direct bindings
    property NetworkCabinetCalculator calculator: NetworkCabinetCalculator {
        id: networkCabinet
    }
    
    property bool darkMode: window.modeToggled
    
    // Help popup
    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>DC-M1 Network Cabinet Calculator</h3><br>" +
                   "This calculator helps you visualize and configure a DC-M1 electrical network cabinet.<br><br>" +
                   "<b>Features:</b><br>" +
                   "• 3-phase 415V distribution cabinet<br>" +
                   "• Up to 4 ways configurable as either:<br>" +
                   "  - 630A disconnects with 630A fuses (for main feeds)<br>" +
                   "  - 2x160A disconnects with 63A fuses (for dual services)<br>" +
                   "  - 1x160A disconnect with 63A fuse and cover plate (for single service)<br>" +
                   "• Configurable cable options for all ways:<br>" +
                   "  - 70mm² to 300mm² for 630A ways<br>" +
                   "  - 16mm² to 50mm² for 160A service ways<br>" +
                   "  - Aluminum or Copper conductor material selection<br>" +
                   "• Optional streetlighting panel with 16A MCBs<br>" +
                   "• Optional service panel for additional connections<br><br>" +
                   "Customize the configuration to match your installation requirements."
        widthFactor: 0.4
        heightFactor: 0.6
    }
    
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 10
        
        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "DC-M1 Network Cabinet Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                ToolTip.text: "Help"
                onClicked: popUpText.open()
            }
        }
        
        // Main content
        WaveCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            titleVisible: false
                
            // Configuration panel
            NetworkCabinetConfig {
                id: cabinetConfig
                anchors.fill: parent
                darkMode: cabinetCalculator.darkMode

                calculator: networkCabinet
            }
        }
        WaveCard {
            title: "DC-M1 Network Cabinet"
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Cabinet visualization
            NetworkCabinetDiagram {
                id: cabinetDiagram
                anchors.fill: parent
                darkMode: cabinetCalculator.darkMode

                calculator: networkCabinet
            }
        }
        
        // // Bottom section with additional info
        // WaveCard {
        //     title: "Cabinet Specifications"
        //     Layout.fillWidth: true
        //     Layout.preferredHeight: 220
            
        //     GridLayout {
        //         anchors.fill: parent
        //         columns: 2
        //         columnSpacing: 20
        //         rowSpacing: 10
                
        //         // Static cabinet specifications
        //         Label { text: "Cabinet Type:"; font.bold: true; Layout.alignment: Qt.AlignRight }
        //         Label { text: "DC-M1 Network Distribution Cabinet"; Layout.fillWidth: true }
                
        //         Label { text: "Voltage System:"; font.bold: true; Layout.alignment: Qt.AlignRight }
        //         Label { text: "415V Three-Phase"; Layout.fillWidth: true }
                
        //         Label { text: "Disconnector Rating:"; font.bold: true; Layout.alignment: Qt.AlignRight }
        //         Label { text: "630A DIN Fuse Disconnects"; Layout.fillWidth: true }
                
        //         Label { text: "Maximum Cable Size:"; font.bold: true; Layout.alignment: Qt.AlignRight }
        //         Label { text: "300mm² Aluminum"; Layout.fillWidth: true }
                
        //         Label { text: "Typical Cable Size:"; font.bold: true; Layout.alignment: Qt.AlignRight }
        //         Label { text: "185mm² Aluminum"; Layout.fillWidth: true }
                
        //         // Dynamic specifications based on current configuration
        //         Label {
        //             text: "Service Connections:"
        //             font.bold: true
        //             Layout.alignment: Qt.AlignRight
        //             visible: networkCabinet.showServicePanel || (networkCabinet.wayTypes && networkCabinet.wayTypes.indexOf(1) >= 0)
        //         }
                
        //         Label {
        //             text: "50-160A 3-Phase Fuse Disconnects"
        //             Layout.fillWidth: true
        //             visible: networkCabinet.showServicePanel || (networkCabinet.wayTypes && networkCabinet.wayTypes.indexOf(1) >= 0)
        //         }
        //     }
        // }
    }
}
