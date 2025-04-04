import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../style"
import "../buttons"

GridLayout {
    id: resultsLayout
    columns: 2
    rowSpacing: 18
    
    // Properties that need to be passed from parent
    property real currentVoltageDropValue: 0
    property string selectedVoltage: "415V"
    property real diversityFactor: 1.0
    property string combinedRatingInfo: "N/A"
    property real totalLoad: 0.0
    property real current: 0.0
    
    // Signal for buttons
    signal viewDetailsClicked()
    signal saveResultsClicked()
    signal viewChartClicked()
    
    // Calculate percentage as local property for efficiency
    property real dropPercentage: currentVoltageDropValue / (parseFloat(selectedVoltage.slice(0, -1)) || 1) * 100
    
    Label { text: "Voltage Drop: " }

    Label {
        id: dropValue
        text: currentVoltageDropValue.toFixed(2) + " V"
        font.weight: Font.Medium
    }

    Label { text: "Percentage Drop: " }

    Label {
        id: dropPercent
        text: dropPercentage.toFixed(2) + "%"
        color: dropPercentage > 5 ? "red" : "green"
    }

    Label { text: "Diversity Factor Applied: " }

    Label {
        text: diversityFactor.toFixed(2)
    }

    // Network Fuse Size display
    Label { text: "Network Fuse / Rating:" }
    Label {
        id: networkFuseSizeText
        text: combinedRatingInfo || "N/A"
        color: text !== "N/A" && text !== "Not specified" && text !== "Error" ? 
               "blue" : (text === "Error" ? "red" : Universal.foreground)
        font.bold: text !== "N/A" && text !== "Not specified" && text !== "Error"
        Layout.fillWidth: true
    }

    Label { text: "Total Load (kVA):" }
    Label {
        id: totalLoadText
        text: totalLoad.toFixed(1)
        font.bold: true
        Layout.fillWidth: true
    }

    Label { text: "Current (A):" }
    Label {
        id: currentText
        text: current.toFixed(1)
        font.bold: true
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        Layout.fillWidth: true
        height: 8
        radius: 4

        Rectangle {
            width: parent.width * Math.min((currentVoltageDropValue / (parseFloat(selectedVoltage.slice(0, -1)) || 1) * 100) / 10, 1)
            height: parent.height
            radius: 4
            color: dropPercentage > 5 ? "red" : "green"
            Behavior on width { NumberAnimation { duration: 200 } }
        }
    }

    RowLayout {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        Layout.topMargin: 10
        
        StyledButton {
            text: "Save Results"
            icon.name: "Save"
            enabled: currentVoltageDropValue > 0
            onClicked: saveResultsClicked()
        }

        StyledButton {
            text: "Show Details"
            icon.name: "Info"
            enabled: currentVoltageDropValue > 0
            onClicked: viewDetailsClicked()
        }

        StyledButton {
            text: "View Chart"
            icon.name: "Chart"
            enabled: currentVoltageDropValue > 0
            onClicked: viewChartClicked()
        }
    }
    
    // Methods to update values programmatically
    function updateCombinedRatingInfo(value) {
        networkFuseSizeText.text = value;
    }
    
    function updateTotalLoad(value) {
        totalLoadText.text = value.toFixed(1);
    }
    
    function updateCurrent(value) {
        currentText.text = value.toFixed(1);
    }
}
