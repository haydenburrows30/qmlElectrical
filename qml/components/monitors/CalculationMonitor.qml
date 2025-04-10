import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    
    // Properties
    property var calculator
    property int updateIntervalMs: 100
    property bool showDetails: true
    
    // Visual properties
    color: "transparent"
    border.color: "#cccccc"
    border.width: 0
    
    // Default size
    width: parent ? parent.width : 300
    height: showDetails ? 80 : 40
    
    // Progress update timer
    Timer {
        id: updateTimer
        interval: root.updateIntervalMs
        running: visible && calculator && calculator.calculationInProgress // Use property accessor
        repeat: true
        onTriggered: {
            progressBar.value = calculator.calculationProgress // Use property accessor
            updateStatusText()
        }
    }
    
    // Update the status text based on calculator state
    function updateStatusText() {
        if (!calculator) {
            statusText.text = "No calculator"
            return
        }
        
        if (calculator.calculationInProgress) { // Use property accessor
            statusText.text = "Calculating... " + Math.round(calculator.calculationProgress * 100) + "%" // Use property accessor
            statusText.color = "#106010"
        } else {
            statusText.text = "Calculation Complete"
            statusText.color = "#101060"
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Label {
                id: statusText
                text: "Ready"
                font.pixelSize: 12
                Layout.fillWidth: true
            }
            
            Button {
                text: "Cancel"
                visible: calculator && calculator.calculationInProgress // Use property accessor
                implicitWidth: 70
                implicitHeight: 24
                font.pixelSize: 10
                padding: 2
                
                onClicked: {
                    if (calculator) calculator.cancelCalculation()
                }
            }
            
            Label {
                text: calculator && calculator.profilingEnabled ? "Profiling" : "" // Use property accessor
                color: "#805020"
                font.pixelSize: 9
                font.italic: true
                visible: calculator && calculator.profilingEnabled // Use property accessor
            }
        }
        
        ProgressBar {
            id: progressBar
            Layout.fillWidth: true
            from: 0.0
            to: 1.0
            value: calculator ? calculator.calculationProgress : 0 // Use property accessor
            visible: calculator && calculator.calculationInProgress // Use property accessor
        }
        
        Item {
            id: detailsItem
            visible: showDetails
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Additional details could be added here
            // For example, performance metrics
        }
    }
    
    // Initial status update
    Component.onCompleted: {
        updateStatusText()
    }
    
    // Update status when calculation state changes
    Connections {
        target: calculator
        
        function onCalculationStatusChanged() {
            updateStatusText()
        }
        
        function onCalculationProgressChanged(progress) {
            progressBar.value = progress
            updateStatusText()
        }
    }
}