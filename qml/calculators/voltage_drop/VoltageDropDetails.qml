import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal


import "../../components"
import "../../components/buttons"
import "../../components/style"

Popup {
    id: detailsPopup
    modal: true
    focus: true
    width: 600
    height: 400
    
    // Properties to receive data from parent
    property string voltageSystem: ""
    property bool admdEnabled: false
    property real kvaPerHouse: 0
    property int numHouses: 0
    property real diversityFactor: 1.0
    property real totalKva: 0
    property real current: 0
    property string cableSize: ""
    property string conductorMaterial: ""
    property string coreType: ""
    property string length: "0"
    property string installationMethod: ""
    property string temperature: "25"
    property string groupingFactor: "1.0"
    property string combinedRatingInfo: "N/A"
    property real voltageDropValue: 0
    property real dropPercentage: 0

    signal closeRequested()
    signal saveToPdfRequested()
    signal pdfSaveResult(bool success, string message)

    ScrollView {
        id: detailsScrollView
        anchors.fill: parent
        clip: true

        ColumnLayout {
            id: detailsContent
            width: parent.width
            
            Label {
                text: "Calculation Results"
                font.bold: true
                font.pixelSize: 16
            }

            GridLayout {
                id: detailsGrid
                columns: 2
                columnSpacing: 10
                
                Layout.fillWidth: true

                // System Configuration
                Label { text: "System Configuration"; font.bold: true; Layout.columnSpan: 2 }
                Label { text: "Voltage System:" }
                Label { text: voltageSystem }
                Label { text: "ADMD Status:" }
                Label { text: admdEnabled ? "Enabled (1.5×)" : "Disabled" }

                // Load Details
                Label { text: "Load Details"; font.bold: true; Layout.columnSpan: 2; Layout.topMargin: 10 }
                Label { text: "KVA per House:" }
                Label { text: kvaPerHouse.toFixed(1) + " kVA" }
                Label { text: "Number of Houses:" }
                Label { text: numHouses.toString() }
                Label { text: "Diversity Factor:" }
                Label { text: diversityFactor.toFixed(3) }
                Label { text: "Total Load:" }
                Label { text: totalKva.toFixed(1) + " kVA" }
                Label { text: "Current:" }
                Label { text: current.toFixed(1) + " A" }

                // Cable Details
                Label { text: "Cable Details"; font.bold: true; Layout.columnSpan: 2; Layout.topMargin: 10 }
                Label { text: "Cable Size:" }
                Label { text: cableSize + " mm²" }
                Label { text: "Material:" }
                Label { text: conductorMaterial }
                Label { text: "Configuration:" }
                Label { text: coreType }
                Label { text: "Length:" }
                Label { text: length + " m" }
                Label { text: "Installation:" }
                Label { text: installationMethod }
                Label { text: "Temperature:" }
                Label { text: temperature + " °C" }
                Label { text: "Grouping Factor:" }
                Label { text: groupingFactor }

                // Results
                Label { text: "Results"; font.bold: true; Layout.columnSpan: 2; Layout.topMargin: 10 }
                Label { text: "Network Fuse / Rating:" }
                Label {
                    text: combinedRatingInfo 
                    color: text !== "N/A" && text !== "Not specified" && text !== "Error" ? 
                           "blue" : (text === "Error" ? "red" : window.modeToggled ? "#ffffff" : "#000000")
                    font.bold: text !== "N/A" && text !== "Not specified" && text !== "Error"
                }
                Label { text: "Voltage Drop:" }
                Label { 
                    text: voltageDropValue.toFixed(2) + " V"
                    color: dropPercentage > 5 ? "red" : "green"
                }
                Label { text: "Drop Percentage:" }
                Label { 
                    text: dropPercentage.toFixed(2) + "%"
                    color: dropPercentage > 5 ? "red" : "green"
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                
                
                StyledButton {
                    text: "Save to PDF"
                    icon.source: "../../../icons/rounded/save.svg"
                    onClicked: detailsPopup.saveToPdfRequested()
                }
                
                StyledButton {
                    icon.source: "../../../icons/rounded/close.svg"
                    text: "Close"
                    onClicked: detailsPopup.closeRequested()
                }
            }
        }
    }
}
