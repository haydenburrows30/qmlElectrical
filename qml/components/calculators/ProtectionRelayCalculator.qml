import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import "../style"
import "../backgrounds"

import ProtectionRelay 1.0

Item {
    id: protectionRelayCard

    property ProtectionRelayCalculator relay: ProtectionRelayCalculator {}

    Popup {
        id: tipsPopup
        width: 700
        height: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        Text {
            anchors.fill: parent
            text: { "<h3>Protection Relay Calculator</h3><br>" +
                    "This calculator estimates the operating time of a protection relay for a given fault current and settings.<br><br>" +
                    "<b>Pickup Current:</b> The current at which the relay should trip.<br>" +
                    "<b>Time Dial Setting:</b> The time dial setting of the relay.<br>" +
                    "<b>Curve Type:</b> The type of curve used by the relay.<br>" +
                    "<br>" +
                    "<b>Fault Current:</b> The current at which the fault occurs.<br>" +
                    "<br>" +
                    "The operating time of the relay is calculated based on the selected settings and fault current.<br>" +
                    "The time-current curve of the relay is also displayed for reference.<br>" +
                    "<br>" +
                    "Note: The operating time is an approximation and may vary based on the relay model and manufacturer.<br>" +
                    "<br>" +
                    "For more information, refer to the relay's datasheet or contact the manufacturer.<br>" +
                    "<br>" +
                    "<b>References:</b><br>" +
                    "IEEE Standard C37.112-1996<br>" +
                    "IEC 60255-151:2009<br>" +
                    "ANSI/IEEE C37.112-1996<br>"}
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        
        anchors.centerIn: parent

        ColumnLayout {
            Layout.preferredWidth: 350
            id: settingsColumn

            WaveCard {
                title: "Relay Settings"
                Layout.fillWidth: true
                Layout.minimumHeight: 500
                id: results
                showSettings: true

                GridLayout {
                    columns: 2
                    
                    

                    Label { text: "Device Type:" }
                    ComboBox {
                        id: deviceType
                        model: relay.deviceTypes
                        textRole: "type"
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) {
                                let device = model[currentIndex]
                                // Get ratings without duplicates
                                let ratings = relay.getUniqueDeviceRatings(device.type)
                                ratingCombo.model = ratings
                                breakingCapacity.text = device.breaking_capacity
                            }
                        }
                        Layout.fillWidth: true
                    }

                    Label { text: "Rating:" }
                    ComboBox {
                        id: ratingCombo
                        textRole: "rating"
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0 && model) {
                                let rating = model[currentIndex]
                                pickupCurrent.text = rating.rating
                                deviceDescription.text = rating.description
                                
                                // Determine curve type based on breaker type and rating
                                if (deviceType.currentText === "MCB") {
                                    breakerCurveCombo.visible = true
                                    breakerCurveCombo.currentIndex = 1  // Default to C curve
                                } else {
                                    breakerCurveCombo.visible = false
                                    curveType.currentIndex = 2  // Set to Extremely Inverse
                                }
                            }
                        }
                        Layout.fillWidth: true
                    }

                    Label { text: "Breaker Curve:" }
                    ComboBox {
                        id: breakerCurveCombo
                        visible: deviceType.currentText === "MCB"
                        model: ["B", "C", "D"]
                        onCurrentTextChanged: {
                            if (currentText) {
                                // Set curveType index based on breaker curve
                                switch(currentText) {
                                    case "B": curveType.currentIndex = 0; break; // Standard Inverse
                                    case "C": curveType.currentIndex = 1; break; // Very Inverse
                                    case "D": curveType.currentIndex = 2; break; // Extremely Inverse
                                }
                            }
                        }
                        Layout.fillWidth: true
                        
                        ToolTip {
                            text: "B: 3-5x In\nC: 5-10x In\nD: 10-20x In"
                            visible: parent.hovered
                        }
                    }

                    Label { text: "Breaking Capacity:" }
                    TextField {
                        id: breakingCapacity
                        placeholderText: "Enter breaking capacity"
                        validator: IntValidator { bottom: 0 }
                        color: {
                            if (!acceptableInput) return "red"
                            if (deviceType.currentText === "MCB" && parseInt(text) > 10000) return "red"
                            if (deviceType.currentText === "MCCB" && parseInt(text) < 10000) return "red"
                            return activeFocus ? "black" : "gray"
                        }
                        
                        ToolTip {
                            text: {
                                if (deviceType.currentText === "MCB") return "Valid range: 1000-10000A"
                                if (deviceType.currentText === "MCCB") return "Valid range: 10000-50000A"
                                return "Enter breaking capacity"
                            }
                            visible: parent.hovered || parent.activeFocus
                        }

                        onEditingFinished: {
                            if (deviceType.currentIndex >= 0 && text) {
                                let device = deviceType.model[deviceType.currentIndex]
                                let capacity = parseInt(text)
                                if (relay.updateBreakingCapacity(device.type, capacity)) {
                                    // Force reload models
                                    deviceType.model = undefined  // Clear first
                                    deviceType.model = relay.deviceTypes
                                    
                                    // Update ratings for current device type
                                    ratingCombo.model = relay.getDeviceRatings(device.type)
                                    
                                    // Update curve type index instead of text
                                    curveType.currentIndex = capacity > 10000 ? 2 : 0
                                } else {
                                    // Reset to previous value if update failed
                                    text = device.breaking_capacity
                                }
                            }
                        }
                        Layout.fillWidth: true
                    }

                    Label { text: "Description:" }
                    TextField {
                        id: deviceDescription
                        readOnly: true
                        Layout.fillWidth: true
                    }

                    Label { text: "Pickup Current (A):" }
                    TextField {
                        id: pickupCurrent
                        placeholderText: "Enter current"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) relay.pickupCurrent = parseFloat(text)
                        Layout.minimumWidth: 180
                    }

                    Label { text: "Time Dial:" }
                    TextField {
                        id: timeDial
                        placeholderText: "Enter TDS"
                        validator: DoubleValidator { bottom: 0; top: 1 }
                        onTextChanged: if(text) relay.timeDial = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Curve Type:" }
                    ComboBox {
                        id: curveType
                        Layout.fillWidth: true
                        model: {
                            if (deviceType.currentText === "MCB") {
                                return ["IEC Standard Inverse", "IEC Very Inverse", "IEC Extremely Inverse"]
                            } else {
                                return ["IEC Extremely Inverse"]
                            }
                        }
                        onCurrentTextChanged: {
                            if (currentText) {
                                relay.setCurveType(currentText)
                            }
                        }
                        
                        Component.onCompleted: {
                            currentIndex = 0
                        }
                        
                        ToolTip {
                            text: "B Curve: Standard Inverse\nC Curve: Very Inverse\nD Curve: Extremely Inverse"
                            visible: parent.hovered
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }

                    Label { text: "Results:" ; Layout.columnSpan: 2 ; font.bold: true ; font.pixelSize: 16}

                    Label { text: "Fault Current (A):" }
                    TextField {
                        id: faultCurrent
                        placeholderText: "Enter fault current"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) relay.faultCurrent = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Operating Time:" }
                    Label {
                        text: relay.operatingTime.toFixed(2) + " s"
                        font.bold: true
                    }
                }
            }
        }

        WaveCard {
            title: "Time-Current Curve"
            Layout.minimumHeight: settingsColumn.height
            Layout.minimumWidth: settingsColumn.height * 1.5


            // Time-Current Curve Chart
            ChartView {
                id: relayChart
                theme: Universal.theme
                anchors.fill: parent

                antialiasing: true
                
                LogValueAxis {
                    id: currentAxis
                    min: 10
                    max: 10000
                    base: 10
                    titleText: "Current (A)"
                }
                
                LogValueAxis {
                    id: timeAxis
                    min: 0.01
                    max: 100
                    base: 10
                    titleText: "Time (s)"
                }

                LineSeries {
                    id: tripCurve
                    name: "Trip Curve"
                    axisX: currentAxis
                    axisY: timeAxis
                }
            }
        }
    }

    // Combined connection that handles both general and device-specific curves
    Connections {
        target: relay
        function onCalculationsComplete() {
            // Try to get device-specific curve points first
            let deviceSpecificPoints = []
            
            if (deviceType.currentIndex >= 0 && pickupCurrent.text) {
                deviceSpecificPoints = relay.getCurvePoints(
                    deviceType.currentText,
                    parseFloat(pickupCurrent.text) || 0
                )
            }
            
            // Clear the existing curve
            tripCurve.clear()
            
            // If we have device-specific points, use those
            if (deviceSpecificPoints.length > 0) {
                for (let point of deviceSpecificPoints) {
                    tripCurve.append(
                        point.multiplier * parseFloat(pickupCurrent.text), 
                        point.time
                    )
                }
            } else {
                // Otherwise fall back to the general curve points
                let generalPoints = relay.curvePoints
                for (let i = 0; i < generalPoints.length; i++) {
                    tripCurve.append(generalPoints[i].current, generalPoints[i].time)
                }
            }
        }
    }
}
