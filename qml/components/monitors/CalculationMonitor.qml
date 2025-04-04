import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../buttons"

Item {
    id: calculationMonitor
    
    property var calculator
    property bool profilingEnabled: false

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

    StyledButton {
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

    Label {
        font.italic: true
        font.pixelSize: 10;
        color: "gray"
        
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: 45
        }
        text: {
            if (calculator && calculator.calculationInProgress) {
                try {
                    var status = calculator.getThreadPoolStatus();
                    if (status && status.active_threads !== undefined) {
                        return "Threads: " + status.active_threads + "/" + status.max_threads;
                    }
                } catch (e) {
                    console.error("Error getting thread status:", e);
                }
                return "Threads: Active";
            return "";
            }
            visible: calculator ? calculator.calculationInProgress : false
        }
    }

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
        z: 10
    }

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