import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import "../style"

import "../popups"

import ProtectionRelay 1.0

Item {
    id: protectionRelayCard

    property ProtectionRelayCalculator relay: ProtectionRelayCalculator {}

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: parent.height + 40
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            RowLayout {
                id: mainLayout
                anchors.centerIn: parent

                ColumnLayout {
                    id: settingsColumn
                    Layout.preferredWidth: 350
                    
                    WaveCard {
                        title: "Relay Settings"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 550
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
                                        
                                        // Update breakerCurveCombo visibility immediately
                                        breakerCurveCombo.visible = device.type === "MCB"
                                    }
                                }
                                Layout.fillWidth: true
                                
                                // Initialize default selection
                                Component.onCompleted: {
                                    if (count > 0) {
                                        currentIndex = 0
                                    }
                                }
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

                            Label { 
                                text: "Breaker Curve:" 
                                visible: breakerCurveCombo.visible
                            }
                            ComboBox {
                                id: breakerCurveCombo
                                visible: false // Initialize as invisible, will be set by deviceType selection
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
                                color: sideBar.modeToggled ? "#404040" : "#e0e0e0"
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
                            TextFieldBlue {
                                id: operatingTimeLabel
                                text: relay.operatingTime.toFixed(2) + " s"
                                font.bold: true
                                color: {
                                    const time = relay.operatingTime;
                                    if (time <= 0.1) return "red"; // Immediate trip - danger
                                    if (time <= 1.0) return "orange"; // Fast trip - warning
                                    return "green"; // Slow trip - good
                                }
                            }

                            // Add trip assessment
                            Label { text: "Trip Assessment:" }
                            TextFieldBlue {
                                text: {
                                    const time = relay.operatingTime;
                                    if (time <= 0.1) return "Instantaneous Trip";
                                    if (time <= 1.0) return "Fast Trip";
                                    if (time <= 10.0) return "Normal Trip";
                                    return "Delayed Trip";
                                }
                                color: operatingTimeLabel.color
                            }

                            Button {
                                id: saveSettingsButton
                                text: "Save Settings"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignRight
                                
                                onClicked: {
                                    // Ensure all fields have valid values before saving
                                    const pickupVal = parseFloat(pickupCurrent.text) || 0;
                                    const timeDialVal = parseFloat(timeDial.text) || 0.5;
                                    
                                    // Save current settings and add them to the comparison list
                                    let settings = {
                                        deviceType: deviceType.currentText || "",
                                        rating: pickupVal.toString(),
                                        timeDial: timeDialVal.toString(),
                                        curveType: curveType.currentText || "IEC Standard Inverse",
                                        operatingTime: relay.operatingTime
                                    };
                                    relay.saveSettings(settings);
                                    savedSettingsPopup.open();
                                }
                            }
                        }
                    }
                    
                    // Additional card for circuit parameters
                    WaveCard {
                        title: "Circuit Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 240
                        visible: advancedMode.checked
                        
                        GridLayout {
                            columns: 2
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            Label { text: "Supply Voltage (V):" }
                            TextField {
                                id: supplyVoltage
                                placeholderText: "Enter voltage"
                                validator: IntValidator { bottom: 110; top: 1000 }
                                text: "400"
                                Layout.fillWidth: true
                            }
                            
                            Label { text: "Cable Length (m):" }
                            TextField {
                                id: cableLength
                                placeholderText: "Enter length"
                                validator: DoubleValidator { bottom: 0 }
                                text: "100"
                                Layout.fillWidth: true
                            }
                            
                            Label { text: "Cable Size (mm²):" }
                            ComboBox {
                                id: cableSize
                                model: ["1.5", "2.5", "4", "6", "10", "16", "25", "35", "50", "70", "95", "120"]
                                currentIndex: 2
                                Layout.fillWidth: true
                            }
                            
                            Button {
                                text: "Calculate Fault Current"
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                onClicked: {
                                    // Calculate fault current based on circuit parameters
                                    let voltage = parseFloat(supplyVoltage.text);
                                    let length = parseFloat(cableLength.text);
                                    let size = parseFloat(cableSize.currentText);
                                    
                                    // Simple calculation (more sophisticated one would be in Python)
                                    let impedance = 0.018 * length / size; // Simplified impedance calculation
                                    let calculatedFaultCurrent = voltage / impedance;
                                    
                                    // Update fault current field
                                    faultCurrent.text = calculatedFaultCurrent.toFixed(1);
                                }
                            }
                        }
                    }
                    
                    // Toggle for advanced mode
                    CheckBox {
                        id: advancedMode
                        text: "Show Advanced Circuit Parameters"
                        checked: false
                    }
                }

                WaveCard {
                    title: "Time-Current Curve"
                    Layout.minimumHeight: settingsColumn.height
                    Layout.minimumWidth: settingsColumn.height // * 1.5


                    // Time-Current Curve Chart
                    ChartView {
                        id: relayChart
                        theme: Universal.theme
                        anchors.fill: parent
                        anchors.margins: 10
                        legend.visible: true
                        legend.alignment: Qt.AlignBottom

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
                        
                        // Add a point marker for the current fault current
                        ScatterSeries {
                            id: faultPoint
                            name: "Fault Point"
                            color: operatingTimeLabel.color
                            markerSize: 15
                            axisX: currentAxis
                            axisY: timeAxis
                        }
                        
                        // Add saved settings series (will be populated from saved settings)
                        LineSeries {
                            id: savedCurve
                            name: "Saved Settings"
                            visible: false
                            axisX: currentAxis
                            axisY: timeAxis
                            color: "gray"
                            width: 2
                            style: Qt.DashLine
                        }
                    }
                    
                    // Add legend toggle
                    CheckBox {
                        text: "Show Legend"
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        checked: true
                        onCheckedChanged: relayChart.legend.visible = checked
                    }
                }
            }
        }
    }

    PopUpText {
        parentCard: results
        popupText: "<h3>Protection Relay Calculator</h3><br>" +
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
                    "ANSI/IEEE C37.112-1996<br>"
    }

    // Popup for saved settings
    Popup {
        id: savedSettingsPopup
        width: 300
        height: 400
        anchors.centerIn: parent
        modal: true
        
        ColumnLayout {
            anchors.fill: parent
            
            Label {
                text: "Saved Settings"
                font.bold: true
                font.pixelSize: 16
            }
            
            ListView {
                id: savedSettingsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: relay.savedSettings
                delegate: ItemDelegate {
                    width: parent.width
                    text: modelData.deviceType + " " + modelData.rating + "A"
                    highlighted: index === savedSettingsList.currentIndex
                    onClicked: {
                        savedSettingsList.currentIndex = index;
                        relay.loadSavedCurve(index);
                        savedCurve.visible = true;
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Button {
                    text: "Compare"
                    enabled: savedSettingsList.currentIndex >= 0
                    onClicked: {
                        // Show the saved curve for comparison
                        savedCurve.visible = true;
                    }
                }
                
                Button {
                    text: "Load"
                    enabled: savedSettingsList.currentIndex >= 0
                    onClicked: {
                        try {
                            // Load the selected settings
                            let settings = relay.savedSettings[savedSettingsList.currentIndex];
                            
                            // Find and set deviceType
                            for (let i = 0; i < deviceType.count; i++) {
                                if (deviceType.model[i].type === settings.deviceType) {
                                    deviceType.currentIndex = i;
                                    break;
                                }
                            }
                            
                            // Set other fields with safe defaults
                            pickupCurrent.text = settings.rating || "1.0";
                            timeDial.text = settings.timeDial || "0.5";
                            
                            // Find and set curveType
                            let curveTypeFound = false;
                            for (let i = 0; i < curveType.count; i++) {
                                if (curveType.model[i] === settings.curveType) {
                                    curveType.currentIndex = i;
                                    curveTypeFound = true;
                                    break;
                                }
                            }
                            
                            // Set default curve type if not found
                            if (!curveTypeFound && curveType.count > 0) {
                                curveType.currentIndex = 0;
                            }
                            
                            savedSettingsPopup.close();
                        } catch (e) {
                            console.error("Error loading settings:", e);
                        }
                    }
                }
                
                Button {
                    text: "Close"
                    onClicked: {
                        savedCurve.visible = false;
                        savedSettingsPopup.close();
                    }
                }
            }
            
            // Add Clear Settings button
            Button {
                text: "Clear All Settings"
                Layout.fillWidth: true
                Layout.topMargin: 10
                
                // Add confirmation dialog
                onClicked: confirmClearDialog.open()
                
                background: Rectangle {
                    color: parent.hovered ? "#ffcccc" : "#ffe0e0"
                    border.color: "#cc0000"
                    border.width: 1
                    radius: 4
                }
            }
        }
    }
    
    // Confirmation dialog for clearing settings
    Dialog {
        id: confirmClearDialog
        title: "Confirm Clear"
        standardButtons: Dialog.Yes | Dialog.No
        modal: true
        anchors.centerIn: parent
        
        Label {
            text: "Are you sure you want to delete all saved settings?\nThis cannot be undone."
        }
        
        onAccepted: {
            relay.clearSettings()
            savedCurve.visible = false
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
            faultPoint.clear()
            
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
            
            // Add point for current fault current and operating time
            if (faultCurrent.text && relay.operatingTime < 100) {
                faultPoint.append(
                    parseFloat(faultCurrent.text),
                    relay.operatingTime
                )
            }
        }
        
        function onSavedCurveReady(points) {
            savedCurve.clear();
            
            if (points && points.length > 0) {
                for (let i = 0; i < points.length; i++) {
                    savedCurve.append(points[i].current, points[i].time);
                }
                savedCurve.visible = true;
            } else {
                console.warn("Received empty curve points");
                savedCurve.visible = false;
            }
        }
    }
}
