import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: calculationMonitor
    
    property var calculator
    property bool profilingEnabled: false
    
    // Add status indicator for background calculations
    BusyIndicator {
        id: calculationBusyIndicator
        anchors {
            right: parent.right
            top: parent.top
            margins: 10
        }
        width: 32
        height: 32
        visible: calculator ? calculator.calculationInProgress : false
        running: visible
    }
    
    // Add progress information
    Rectangle {
        anchors {
            right: parent.right
            top: calculationBusyIndicator.bottom
            margins: 5
        }
        width: 100
        height: 25
        color: "lightgrey"
        opacity: 0.7
        radius: 5
        visible: calculator ? calculator.calculationInProgress : false
        
        Label {
            anchors.centerIn: parent
            text: calculator ? (calculator.calculationProgress * 100).toFixed(0) + "%" : "0%"
            font.bold: true
        }
    }
    
    // Add cancel button
    Button {
        anchors {
            right: parent.right
            top: parent.top
            margins: 50
        }
        text: "Cancel"
        visible: calculator ? calculator.calculationInProgress : false
        onClicked: {
            if (calculator) {
                calculator.cancelCalculation();
            }
        }
    }
    
    // Add thread status indicator with improved error handling
    Text {
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: 45
        }
        text: {
            // Get thread pool status when calculation is in progress
            if (calculator && calculator.calculationInProgress) {
                try {
                    var status = calculator.getThreadPoolStatus();
                    if (status && status.active_threads !== undefined) {
                        return "Threads: " + status.active_threads + "/" + status.max_threads;
                    }
                } catch (e) {
                    console.error("Error getting thread status:", e);
                }
                return "Threads: Active";  // Fallback message
            }
            return "";
        }
        visible: calculator ? calculator.calculationInProgress : false
        font.italic: true
        font.pixelSize: 10
        color: "gray"
    }

    // Add a TextArea to log status information
    TextArea {
        id: statusLog
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 60
        readOnly: true
        font.pixelSize: 10
        visible: profilingEnabled && calculator ? calculator.profilingEnabled : false
        z: 10  // Make sure it's above other elements
        
        // Add connections to log status changes
        Connections {
            target: calculator
            function onCalculationsComplete() {
                statusLog.append("✓ Calculations complete");
            }
            function onCalculationStatusChanged() {
                if (calculator.calculationInProgress) {
                    statusLog.append("⏳ Calculation started");
                } else {
                    statusLog.append("⏹ Calculation finished");
                }
            }
        }
    }
}
