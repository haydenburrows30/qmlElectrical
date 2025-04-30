import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

import ProtectionRelay 1.0

Item {
    id: protectionRelayCard

    property ProtectionRelayCalculator relay: ProtectionRelayCalculator {}

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableMain
            contentWidth: parent.width
            contentHeight: mainLayout.height + 40
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                width: flickableMain.width - 20

                // Header with title and help button
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: settingsRow.width

                    Label {
                        text: "Protection Relay Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        ToolTip.text: "Export to PDF"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        Layout.alignment: Qt.AlignRight
                        icon.source: "../../../icons/rounded/download.svg"

                        onClicked: {
                            // Get additional data to include in the PDF
                            let additionalData = {
                                deviceInfo: {
                                    type: deviceType.currentText,
                                    rating: ratingCombo.currentText,
                                    breaking_capacity: breakingCapacity.text,
                                    description: deviceDescription.text
                                },
                                curveLetterMCB: deviceType.currentText === "MCB" ? breakerCurveCombo.currentText : null
                            }
                            
                            // Add circuit parameters if advanced mode is enabled
                            if (advancedMode.checked) {
                                additionalData.circuitParameters = {
                                    voltage: parseFloat(supplyVoltage.text),
                                    length: parseFloat(cableLength.text),
                                    size: parseFloat(cableSize.currentText),
                                    calculated_fault_current: parseFloat(faultCurrent.text)
                                }
                            }
                            
                            relay.exportToPdf(additionalData)
                        }
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                RowLayout {
                    id: settingsRow
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        id: settingsColumn
                        Layout.maximumWidth: 400

                        WaveCard {
                            title: "Relay Settings"
                            Layout.minimumHeight: 600
                            Layout.fillWidth: true

                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label { text: "Device Type:" }

                                ComboBoxRound {
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
                                            
                                            // Update breaker curve visibility and reset to default
                                            breakerCurveCombo.visible = device.type === "MCB"
                                            if (device.type === "MCB") {
                                                breakerCurveCombo.currentIndex = 1  // Default to C curve
                                            } else {
                                                // For non-MCB devices, set pickup to rating directly
                                                if (ratingCombo.currentIndex >= 0) {
                                                    pickupCurrent.text = ratingCombo.model[ratingCombo.currentIndex].rating
                                                }
                                            }
                                        }
                                    }
                                    Layout.fillWidth: true
                                    
                                    // Initialize default selection
                                    Component.onCompleted: {
                                        if (count > 0) {
                                            currentIndex = 0
                                            // Default curve to B for MCB
                                            if (model[0].type === "MCB") {
                                                breakerCurveCombo.currentIndex = 0 // Select B curve
                                            }
                                        }
                                    }
                                }

                                Label { text: "Rating:" }

                                ComboBoxRound {
                                    id: ratingCombo
                                    textRole: "rating"
                                    onCurrentIndexChanged: {
                                        if (currentIndex >= 0 && model) {
                                            let rating = model[currentIndex]
                                            // For MCBs, set pickup current to actual trip point based on curve type
                                            if (deviceType.currentText === "MCB") {
                                                let multiplier = breakerCurveCombo.currentText === "B" ? 3 :
                                                               breakerCurveCombo.currentText === "C" ? 5 : 10
                                                pickupCurrent.text = (parseFloat(rating.rating) * multiplier).toString()
                                            } else {
                                                pickupCurrent.text = rating.rating
                                            }
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

                                ComboBoxRound {
                                    id: breakerCurveCombo
                                    visible: false // Initialize as invisible, will be set by deviceType selection
                                    model: ["B", "C", "D"]
                                    onCurrentTextChanged: {
                                        if (currentText && deviceType.currentText === "MCB" && ratingCombo.currentIndex >= 0) {
                                            // Update pickup current based on MCB curve selection
                                            let rating = ratingCombo.model[ratingCombo.currentIndex].rating
                                            let multiplier = {
                                                "B": 3,
                                                "C": 5,
                                                "D": 10
                                            }[currentText] || 5
                                            
                                            pickupCurrent.text = (rating * multiplier).toString()
                                            
                                            // Update curve type
                                            switch(currentText) {
                                                case "B": curveType.currentIndex = 0; break;
                                                case "C": curveType.currentIndex = 1; break;
                                                case "D": curveType.currentIndex = 2; break;
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

                                TextFieldRound {
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

                                TextFieldRound {
                                    id: deviceDescription
                                    readOnly: true
                                    Layout.fillWidth: true
                                }

                                Label { text: "Pickup Current (A):" }

                                TextFieldRound {
                                    id: pickupCurrent
                                    Layout.fillWidth: true
                                    placeholderText: "Enter current"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text) relay.pickupCurrent = parseFloat(text)
                                }

                                Label { text: "Time Dial:" }

                                TextFieldRound {
                                    id: timeDial
                                    placeholderText: "Enter TDS"
                                    validator: DoubleValidator { bottom: 0; top: 1 }
                                    onTextChanged: if(text) relay.timeDial = parseFloat(text)
                                    Layout.fillWidth: true
                                }

                                Label { text: "Curve Type:" }

                                ComboBoxRound {
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
                                    color: window.modeToggled ? "#404040" : "#e0e0e0"
                                }

                                Label { text: "Results:" ; Layout.columnSpan: 2 ; font.bold: true ; font.pixelSize: 16}

                                Label { text: "Fault Current (A):" }

                                TextFieldRound {
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

                                StyledButton {
                                    id: saveSettingsButton
                                    text: "Save Settings"
                                    icon.source: "../../../icons/rounded/save.svg"
                                    Layout.columnSpan: 2
                                    Layout.alignment: Qt.AlignRight
                                    ToolTip.text: "Save and compare settings"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500

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

                                // Toggle for advanced mode
                                CheckBox {
                                    id: advancedMode
                                    Layout.columnSpan: 2
                                    text: "Show Advanced Circuit Parameters"
                                    checked: false
                                }
                            }
                        }

                        // Additional card for circuit parameters
                        WaveCard {
                            title: "Circuit Parameters"
                            Layout.minimumHeight: 220
                            Layout.fillWidth: true
                            visible: advancedMode.checked
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                uniformCellWidths: true
                                
                                Label { text: "Supply Voltage (V):" }
                                TextFieldRound {
                                    id: supplyVoltage
                                    placeholderText: "Enter voltage"
                                    validator: IntValidator { bottom: 110; top: 1000 }
                                    text: "400"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Cable Length (m):" }
                                TextFieldRound {
                                    id: cableLength
                                    placeholderText: "Enter length"
                                    validator: DoubleValidator { bottom: 0 }
                                    text: "100"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Cable Size (mm²):" }

                                ComboBoxRound {
                                    id: cableSize
                                    model: ["1.5", "2.5", "4", "6", "10", "16", "25", "35", "50", "70", "95", "120"]
                                    currentIndex: 2
                                    Layout.fillWidth: true
                                }
                                
                                StyledButton {
                                    text: "Calculate Fault Current"
                                    icon.source: "../../../icons/rounded/bolt.svg"
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    onClicked: {
                                        // Use the improved calculation method from the backend
                                        let voltage = parseFloat(supplyVoltage.text);
                                        let length = parseFloat(cableLength.text);
                                        let size = parseFloat(cableSize.currentText);
                                        
                                        // Call the improved Python implementation instead of the simplified formula
                                        let calculatedFaultCurrent = relay.calculateFaultCurrent(voltage, length, size);
                                        
                                        // Update fault current field
                                        faultCurrent.text = calculatedFaultCurrent.toFixed(1);
                                    }
                                }
                            }
                        }
                    }

                    WaveCard {
                        title: "Time-Current Curve"
                        Layout.minimumHeight: settingsColumn.height
                        Layout.minimumWidth: settingsColumn.height

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
                            
                            // Add this property to control logarithmic point display
                            property bool useLogarithmicPoints: true

                            // Add legend toggle
                            CheckBox {
                                text: "Show Legend"
                                anchors.top: parent.top
                                anchors.right: parent.right
                                // anchors.margins: 10
                                anchors.topMargin: -50
                                checked: true
                                onCheckedChanged: relayChart.legend.visible = checked
                            }
                        }

                        
                    }
                }
            }
        }
    }

    PopUpText {
        id: popUpText
        parentCard: topHeader
        widthFactor: 0.6
        heightFactor: 0.6
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

    MessagePopup {
        id: messagePopup
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
                
                StyledButton {
                    text: "Compare"
                    icon.source: "../../../icons/rounded/compare.svg"
                    enabled: savedSettingsList.currentIndex >= 0
                    onClicked: {
                        // Show the saved curve for comparison
                        savedCurve.visible = true;
                    }
                }
                
                StyledButton {
                    text: "Load"
                    icon.source: "../../../icons/rounded/folder_open.svg"
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
                
                StyledButton {
                    text: "Close"
                    icon.source: "../../../icons/rounded/close.svg"
                    onClicked: {
                        savedCurve.visible = false;
                        savedSettingsPopup.close();
                    }
                }
            }
            
            // Add Clear Settings button
            StyledButton {
                text: "Clear All Settings"
                icon.source: "../../../icons/rounded/close.svg"
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
                // Use the improved logarithmically distributed curve points
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
            
            // Ensure axis ranges adapt to the curve points
            adjustAxisRanges()
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
        
        function onPdfExportStatusChanged(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }
    
    // Add this function to ensure chart axis ranges adapt to the data
    function adjustAxisRanges() {
        if (tripCurve.count === 0) return
        
        let minCurrent = Number.MAX_VALUE
        let maxCurrent = 0
        let minTime = Number.MAX_VALUE
        let maxTime = 0
        
        // Find the min/max values in the current curve
        for (let i = 0; i < tripCurve.count; i++) {
            let point = tripCurve.at(i)
            minCurrent = Math.min(minCurrent, point.x)
            maxCurrent = Math.max(maxCurrent, point.x)
            minTime = Math.min(minTime, point.y)
            maxTime = Math.max(maxTime, point.y)
        }
        
        // Include fault point in range calculation if visible
        if (faultPoint.count > 0) {
            let point = faultPoint.at(0)
            minCurrent = Math.min(minCurrent, point.x)
            maxCurrent = Math.max(maxCurrent, point.x)
            minTime = Math.min(minTime, point.y)
            maxTime = Math.max(maxTime, point.y)
        }
        
        // Include saved curve in range calculation if visible
        if (savedCurve.visible && savedCurve.count > 0) {
            for (let i = 0; i < savedCurve.count; i++) {
                let point = savedCurve.at(i)
                minCurrent = Math.min(minCurrent, point.x)
                maxCurrent = Math.max(maxCurrent, point.x)
                minTime = Math.min(minTime, point.y)
                maxTime = Math.max(maxTime, point.y)
            }
        }
        
        // Add margins to the ranges (10% on each side)
        const currentMargin = (maxCurrent - minCurrent) * 0.1
        const timeMargin = (maxTime - minTime) * 0.1
        
        // Set the new axis ranges with some limits to avoid extreme values
        currentAxis.min = Math.max(minCurrent * 0.9, 10)
        currentAxis.max = Math.min(maxCurrent * 1.1, 10000)
        timeAxis.min = Math.max(minTime * 0.9, 0.01)
        timeAxis.max = Math.min(maxTime * 1.1, 100)
    }
}
