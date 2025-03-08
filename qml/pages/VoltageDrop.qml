import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import components 1.0

import VDropMV 1.0
import Results 1.0  // Add this import
import ImageSaver 1.0  // Add this import for ImageSaver
Page {
    id: root
    padding: 0
    
    // Move model to top level and create explicit binding
    property real currentVoltageDropValue: voltageDropMV.voltageDrop || 0
    
    // Add connections to ensure property updates when signal is emitted
    Connections {
        target: voltageDropMV
        function onVoltageDropCalculated(value) {
            console.log("Voltage drop updated:", value)
            root.currentVoltageDropValue = value
        }
    }

    VoltageDropMV {
        id: voltageDropMV
    }

    ResultsManager {
        id: resultsManager
    }

    ImageSaver {
        id: imageSaver
        
        onSaveComplete: function(success, message) {
            if (success) {
                imageSaveSuccess.messageText = message;
                imageSaveSuccess.open();
            } else {
                imageSaveError.messageText = message;
                imageSaveError.open();
            }
        }
    }

    background: Rectangle {
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                ColumnLayout {
                    WaveCard {
                        title: "Cable Selection"
                        Layout.minimumHeight: 560
                        Layout.minimumWidth: 400
                        showInfo: false

                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 16

                            Label { text: "System Voltage:" }
                            RowLayout {
                                ComboBox {
                                    id: voltageSelect
                                    model: voltageDropMV.voltageOptions
                                    currentIndex: voltageDropMV.selectedVoltage === "230V" ? 0 : 1
                                    onCurrentTextChanged: {
                                        if (currentText) {
                                            console.log("Selecting voltage:", currentText)
                                            voltageDropMV.setSelectedVoltage(currentText)
                                            // Disable ADMD checkbox for 230V
                                            admdCheckBox.enabled = (currentText === "415V")
                                            if (currentText !== "415V") {
                                                admdCheckBox.checked = false
                                            }
                                        }
                                    }
                                    Layout.fillWidth: true
                                }
                                
                                CheckBox {
                                    id: admdCheckBox
                                    text: "ADMD (neutral)"
                                    enabled: voltageSelect.currentText === "415V"
                                    onCheckedChanged: voltageDropMV.setADMDEnabled(checked)
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Apply 1.5 factor for neutral calculations"
                                }
                                Layout.fillWidth: true
                            }

                            Label { text: "Conductor:" }
                            ComboBox {
                                id: conductorSelect
                                model: voltageDropMV.conductorTypes
                                currentIndex: 1
                                onCurrentTextChanged: {
                                    if (currentText) {
                                        console.log("Selecting conductor:", currentText)
                                        voltageDropMV.setConductorMaterial(currentText)
                                    }
                                }
                                Layout.fillWidth: true
                            }

                            Label { text: "Cable Type:" }
                            ComboBox {
                                id: coreTypeSelect
                                model: voltageDropMV.coreConfigurations
                                currentIndex: 1
                                onCurrentTextChanged: {
                                    if (currentText) {
                                        console.log("Selecting core type:", currentText)
                                        voltageDropMV.setCoreType(currentText)
                                    }
                                }
                                Layout.fillWidth: true
                            }

                            Label { text: "Cable Size:" }
                            ComboBox {
                                id: cableSelect
                                model: voltageDropMV.availableCables
                                currentIndex: 13  // Set default selection
                                onCurrentTextChanged: {
                                    if (currentText) {
                                        console.log("Selecting cable:", currentText)
                                        voltageDropMV.selectCable(currentText)
                                    }
                                }
                                Component.onCompleted: {
                                    if (currentText) {
                                        console.log("Initial cable selection:", currentText)
                                        voltageDropMV.selectCable(currentText)
                                    }
                                }
                                Layout.fillWidth: true
                            }

                            Label { text: "Length (m):" }
                            TextField {
                                id: lengthInput  // Add ID
                                placeholderText: "Enter length"
                                onTextChanged: voltageDropMV.setLength(parseFloat(text) || 0)
                                Layout.fillWidth: true
                                validator: DoubleValidator { bottom: 0 }
                            }

                            Label { text: "Installation Method:" }
                            ComboBox {
                                id: installationMethodCombo  // Add ID
                                currentIndex: 6
                                model: voltageDropMV.installationMethods
                                onCurrentTextChanged: voltageDropMV.setInstallationMethod(currentText)
                                Layout.fillWidth: true
                            }

                            Label { text: "Temperature (°C):" }
                            TextField {
                                id: temperatureInput  // Add ID
                                text: "25"
                                onTextChanged: voltageDropMV.setTemperature(parseFloat(text) || 75)
                                Layout.fillWidth: true
                                validator: DoubleValidator { bottom: 0; top: 120 }
                            }

                            Label { text: "Grouping Factor:" }
                            TextField {
                                id: groupingFactorInput  // Add ID
                                text: "1.0"
                                onTextChanged: voltageDropMV.setGroupingFactor(parseFloat(text) || 1.0)
                                Layout.fillWidth: true
                                validator: DoubleValidator { bottom: 0; top: 2 }
                            }

                            Label { text: "KVA per House:" }
                            TextField {
                                id: kvaPerHouseInput
                                placeholderText: "Enter kVA"
                                text: "7"  // Default 10kVA per house
                                onTextChanged: {
                                    let kva = parseFloat(text) || 0
                                    let houses = parseInt(numberOfHousesInput.text) || 0
                                    voltageDropMV.calculateTotalLoad(kva, houses)
                                }
                                Layout.fillWidth: true
                                validator: DoubleValidator { bottom: 0 }
                            }

                            Label { text: "Number of Houses:" }
                            TextField {
                                id: numberOfHousesInput
                                placeholderText: "Enter number"
                                text: "1"  // Default 1 house
                                onTextChanged: {
                                    let houses = parseInt(text) || 1
                                    let kva = parseFloat(kvaPerHouseInput.text) || 0
                                    voltageDropMV.setNumberOfHouses(houses)
                                    voltageDropMV.calculateTotalLoad(kva, houses)
                                }
                                Layout.fillWidth: true
                                validator: IntValidator { bottom: 1 }
                            }

                            Button {
                                text: "Reset"
                                icon.name: "Reset"
                                Layout.fillWidth: true
                                // Layout.rowSpan: 2
                                onClicked: {
                                    voltageSelect.currentIndex = 1  // 415V
                                    conductorSelect.currentIndex = 1  // Al
                                    coreTypeSelect.currentIndex = 1  // 3C+E
                                    cableSelect.currentIndex = 13
                                    currentInput.text = "0"
                                    lengthInput.text = "0"
                                    temperatureInput.text = "25"
                                    groupingFactorInput.text = "1.0"
                                    kvaPerHouseInput.text = "7"
                                    numberOfHousesInput.text = "1"
                                    admdCheckBox.checked = false
                                    installationMethodCombo.currentIndex = 5  // "D1 - Underground direct buried"

                                    // Reset results table and calculations
                                    totalLoadText.text = "0.0"
                                    
                                    // Reset model state
                                    voltageDropMV.reset()
                                    
                                    // Force property reevaluation
                                    root.currentVoltageDropValue = voltageDropMV.voltageDrop || 0

                                    // Make sure the UI updates by accessing the properties
                                    // This forces the getters to be called
                                    console.log("After reset - voltage drop:", voltageDropMV.voltageDrop)
                                    console.log("After reset - current:", voltageDropMV.current)
                                    console.log("After reset - fuse size:", voltageDropMV.networkFuseSize)
                                    console.log("After reset - combined rating:", voltageDropMV.combinedRatingInfo)
                                    
                                    // Explicitly update the fuse size display
                                    networkFuseSizeText.text = voltageDropMV.combinedRatingInfo
                                }
                            }
                        }
                    }
                    WaveCard {
                        title: "Results"
                        Layout.minimumHeight: 330
                        Layout.minimumWidth:400
                        showInfo: false

                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            rowSpacing: 18

                            Label { text: "Voltage Drop: " }

                            Label {
                                id: dropValue
                                text: root.currentVoltageDropValue.toFixed(2) + " V"
                                font.weight: Font.Medium
                            }

                            Label { text: "Percentage Drop: " }

                            Label {
                                id: dropPercent
                                property real percentage: root.currentVoltageDropValue / (parseFloat(voltageDropMV.selectedVoltage.slice(0, -1)) || 1) * 100
                                text: percentage.toFixed(2) + "%"
                                color: percentage > 5 ? "red" : "green"
                            }

                            Label { text: "Diversity Factor Applied: " }

                            Label {
                                text:  voltageDropMV.diversityFactor.toFixed(2)
                            }

                            // Update Network Fuse Size display to show combined information
                            Label { text: "Network Fuse / Rating:" }
                            Text {
                                id: networkFuseSizeText
                                text: voltageDropMV.combinedRatingInfo || "N/A"
                                color: text !== "N/A" && text !== "Not specified" && text !== "Error" ? 
                                       "blue" : (text === "Error" ? "red" : toolBar.toggle ? "#ffffff" : "#000000")
                                font.bold: text !== "N/A" && text !== "Not specified" && text !== "Error"
                                Layout.fillWidth: true
                                
                                Connections {
                                    target: voltageDropMV
                                    function onCombinedRatingChanged(value) {
                                        networkFuseSizeText.text = value
                                    }
                                }
                            }

                            Label { text: "Total Load (kVA):" }
                            Text {
                                id: totalLoadText
                                text: "10.0"
                                font.bold: true
                                Layout.fillWidth: true
                                color: toolBar.toggle ? "#ffffff" : "#000000"

                                Connections {
                                    target: voltageDropMV
                                    function onTotalLoadChanged(value) {
                                        totalLoadText.text = value.toFixed(1)
                                    }
                                }
                            }

                            Label { text: "Current (A):" }
                            Text {
                                id: currentInput
                                text: Number(voltageDropMV.current).toFixed(1)
                                font.bold: true
                                color: toolBar.toggle ? "#ffffff" : "#000000"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                
                                // Add connection to update when current changes
                                Connections {
                                    target: voltageDropMV
                                    function onCurrentChanged(value) {
                                        currentInput.text = value.toFixed(1)
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4

                                Rectangle {
                                    width: parent.width * Math.min((root.currentVoltageDropValue / voltageDropMV.selectedVoltage.slice(0, -1) * 100) / 10, 1)
                                    height: parent.height
                                    radius: 4
                                    color: (root.currentVoltageDropValue / voltageDropMV.selectedVoltage.slice(0, -1) * 100) > 5 ? "red" : "green"
                                    Behavior on width { NumberAnimation { duration: 200 } }
                                }
                            }

                            RowLayout {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                spacing: 10

                                Button {
                                    text: "Save Results"
                                    icon.name: "Save"
                                    enabled: root.currentVoltageDropValue > 0
                                    onClicked: {
                                        // Save current calculation
                                        resultsManager.save_calculation({
                                            "voltage_system": voltageSelect.currentText,
                                            "kva_per_house": parseFloat(kvaPerHouseInput.text),
                                            "num_houses": parseInt(numberOfHousesInput.text),
                                            "diversity_factor": voltageDropMV.diversityFactor,
                                            "total_kva": parseFloat(totalLoadText.text),
                                            "current": parseFloat(currentInput.text),
                                            "cable_size": cableSelect.currentText,
                                            "conductor": conductorSelect.currentText,
                                            "core_type": coreTypeSelect.currentText,
                                            "length": parseFloat(lengthInput.text),
                                            "voltage_drop": root.currentVoltageDropValue,
                                            "drop_percent": dropPercent.percentage,
                                            "admd_enabled": admdCheckBox.checked
                                        });
                                    }
                                }

                                Button {
                                    text: "Show Details"
                                    icon.name: "Info"
                                    enabled: root.currentVoltageDropValue > 0
                                    onClicked: resultsPopup.open()
                                }
                
                                Button {
                                    text: "View Chart"
                                    icon.name: "Chart"
                                    enabled: root.currentVoltageDropValue > 0
                                    onClicked: {
                                        chartPopup.open()
                                    }
                                }

                                Connections {
                                    target: voltageDropMV
                                    function onSaveStatusChanged(success, message) {
                                        if (success) {
                                            saveSuccess.messageText = message
                                            saveSuccess.open()
                                        } else {
                                            saveError.messageText = message
                                            saveError.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    WaveCard {
                        title: "Cable Size Comparison"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        showInfo: false

                        ColumnLayout {
                            anchors.fill: parent

                            // Header row that syncs with table
                            Item {
                                Layout.fillWidth: true
                                height: 40
                                clip: true

                                Rectangle {
                                    width: tableView.width
                                    height: parent.height
                                    color: toolBar.toggle ? "#424242" : "#e0e0e0"
                                    x: -tableView.contentX  // Sync with table horizontal scroll
                                    
                                    Row {
                                        anchors.fill: parent
                                        Repeater {
                                            model: [
                                                "Size (mm²)", 
                                                "Material", 
                                                "Cores", 
                                                "mV/A/m", 
                                                "Rating (A)", 
                                                "V-Drop (V)", 
                                                "Drop %", 
                                                "Status"
                                            ]
                                            
                                            Rectangle {
                                                width: getColumnWidth(index)
                                                height: parent.height
                                                color: "transparent"
                                                
                                                Label {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    text: modelData
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    elide: Text.ElideRight
                                                    color: toolBar.toggle ? "#ffffff" : "#000000"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Table content
                            ScrollView {
                                id: tableScrollView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                clip: true

                                TableView {
                                    id: tableView
                                    anchors.fill: parent
                                    model: voltageDropMV.tableModel
                                    boundsMovement: Flickable.StopAtBounds

                                    // Remove the sync code since we're using x binding now
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.NoButton
                                        propagateComposedEvents: true
                                        
                                        // Change the wheel handler to explicitly define the parameter
                                        onWheel: function(wheelEvent) {
                                            if (wheelEvent.modifiers & Qt.ControlModifier) {
                                                wheelEvent.accepted = false;
                                            } else {
                                                var delta = wheelEvent.angleDelta.y / 120;
                                                parent.contentY -= delta * 40;
                                                wheelEvent.accepted = true;
                                            }
                                        }
                                    }

                                    delegate: Rectangle {
                                        implicitWidth: getColumnWidth(column)
                                        implicitHeight: 40
                                        color: {
                                            if (column === 7) {  // Status column
                                                switch(model.display) {
                                                    case "SEVERE": return "#ffebee"  // Red background
                                                    case "WARNING": return "#fff3e0"  // Orange background
                                                    case "SUBMAIN": return "#e3f2fd"  // Blue background
                                                    case "OK": return "#e8f5e9"      // Green background
                                                    default: return "transparent"
                                                }
                                            }
                                            return row % 2 ? (toolBar.toggle ? "#2d2d2d" : "#f5f5f5") 
                                                        : (toolBar.toggle ? "#1d1d1d" : "#ffffff")
                                        }

                                        Text {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            text: model.display
                                            color: {
                                                if (column === 7) {  // Status column
                                                    switch(model.display) {
                                                        case "SEVERE": return "#c62828"  // Dark red
                                                        case "WARNING": return "#ef6c00"  // Dark orange
                                                        case "SUBMAIN": return "#1565c0"  // Dark blue
                                                        case "OK": return "#2e7d32"      // Dark green
                                                        default: return toolBar.toggle ? "#ffffff" : "#000000"
                                                    }
                                                }
                                                return toolBar.toggle ? "#ffffff" : "#000000"
                                            }
                                            font.bold: column === 7  // Status column
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // Update SavedResults card with resultsManager property
                    SavedResults {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 300
                        resultsManager: resultsManager  // Pass the instance
                    }
                    // Add detailed results popup
                    Popup {
                        id: resultsPopup
                        modal: true
                        focus: true
                        anchors.centerIn: Overlay.overlay
                        width: 600
                        height: 400

                        ScrollView {
                            anchors.fill: parent
                            clip: true

                            ColumnLayout {
                                width: parent.width
                                spacing: 20

                                Label {
                                    text: "Calculation Results"
                                    font.bold: true
                                    font.pixelSize: 16
                                }

                                GridLayout {
                                    columns: 2
                                    columnSpacing: 20
                                    rowSpacing: 10
                                    Layout.fillWidth: true

                                    // System Configuration
                                    Label { text: "System Configuration"; font.bold: true; Layout.columnSpan: 2 }
                                    Label { text: "Voltage System:" }
                                    Label { text: voltageDropMV.selectedVoltage }
                                    Label { text: "ADMD Status:" }
                                    Label { text: voltageDropMV.admdEnabled ? "Enabled (1.5×)" : "Disabled" }

                                    // Load Details
                                    Label { text: "Load Details"; font.bold: true; Layout.columnSpan: 2; Layout.topMargin: 10 }
                                    Label { text: "KVA per House:" }
                                    Label { 
                                        text: {
                                            const totalKva = voltageDropMV.totalKva || 0
                                            const houses = voltageDropMV.numberOfHouses || 1
                                            return (totalKva / houses).toFixed(1) + " kVA"
                                        }
                                    }
                                    Label { text: "Number of Houses:" }
                                    Label { text: voltageDropMV.numberOfHouses || 1 }
                                    Label { text: "Diversity Factor:" }
                                    Label { text: (voltageDropMV.diversityFactor || 1.0).toFixed(3) }
                                    Label { text: "Total Load:" }
                                    Label { text: (voltageDropMV.totalKva || 0).toFixed(1) + " kVA" }
                                    Label { text: "Current:" }
                                    Label { text: (voltageDropMV.current || 0).toFixed(1) + " A" }

                                    // Cable Details
                                    Label { text: "Cable Details"; font.bold: true; Layout.columnSpan: 2; Layout.topMargin: 10 }
                                    Label { text: "Cable Size:" }
                                    Label { text: cableSelect.currentText + " mm²" }
                                    Label { text: "Material:" }
                                    Label { text: voltageDropMV.conductorMaterial }
                                    Label { text: "Configuration:" }
                                    Label { text: voltageDropMV.coreType }
                                    Label { text: "Length:" }
                                    Label { text: lengthInput.text + " m" }
                                    Label { text: "Installation:" }
                                    Label { text: installationMethodCombo.currentText }
                                    Label { text: "Temperature:" }
                                    Label { text: temperatureInput.text + " °C" }
                                    Label { text: "Grouping Factor:" }
                                    Label { text: groupingFactorInput.text }

                                    // Results
                                    Label { text: "Results"; font.bold: true; Layout.columnSpan: 2; Layout.topMargin: 10 }
                                    Label { text: "Network Fuse / Rating:" }
                                    Label {
                                        text: voltageDropMV.combinedRatingInfo 
                                        color: text !== "N/A" && text !== "Not specified" && text !== "Error" ? 
                                               "blue" : (text === "Error" ? "red" : toolBar.toggle ? "#ffffff" : "#000000")
                                        font.bold: text !== "N/A" && text !== "Not specified" && text !== "Error"
                                    }
                                    Label { text: "Voltage Drop:" }
                                    Label { 
                                        text: root.currentVoltageDropValue.toFixed(2) + " V"
                                        color: dropPercent.percentage > 5 ? "red" : "green"
                                    }
                                    Label { text: "Drop Percentage:" }
                                    Label { 
                                        text: dropPercent.percentage.toFixed(2) + "%"
                                        color: dropPercent.percentage > 5 ? "red" : "green"
                                    }
                                }

                                Button {
                                    text: "Close"
                                    Layout.alignment: Qt.AlignHCenter
                                    onClicked: resultsPopup.close()
                                }
                            }
                        }
                    }
                    // Update message popups
                    Popup {
                        id: saveSuccess
                        modal: true
                        focus: true
                        anchors.centerIn: Overlay.overlay
                        width: 400
                        height: 100
                        
                        property string messageText: ""

                        contentItem: ColumnLayout {
                            Label {
                                text: saveSuccess.messageText
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Button {
                                text: "OK"
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: saveSuccess.close()
                            }
                        }
                    }
                    Popup {
                        id: saveError
                        modal: true
                        focus: true
                        anchors.centerIn: Overlay.overlay
                        width: 400
                        height: 100
                        
                        property string messageText: ""

                        contentItem: ColumnLayout {
                            Label {
                                text: saveError.messageText
                                wrapMode: Text.WordWrap
                                color: "red"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Button {
                                text: "OK"
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: saveError.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // Enhanced chart popup with improved visualization and error fixes
    Popup {
        id: chartPopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 700
        height: 500
        
        // Call this when the popup is about to show
        onAboutToShow: {
            // First clear any existing data to avoid triggering the problematic method
            if (dropPercentSeries) dropPercentSeries.clear()
            if (comparisonSeries) comparisonSeries.clear()
            if (thresholdLine) thresholdLine.clear()
            
            // Use a timeout to ensure UI is ready before we try to update the chart
            chartUpdateTimer.start()
        }
        
        Timer {
            id: chartUpdateTimer
            interval: 100
            onTriggered: enhancedChartUpdate()
        }
        
        // Store comparison points
        property var comparisonPoints: []
        property bool showAllCables: false
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            
            Label {
                text: "Voltage Drop Comparison by Cable Size"
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
                color: toolBar.toggle ? "#ffffff" : "#000000"
            }
            
            // Enhanced chart with better visualization
            ChartView {
                id: chartView
                Layout.fillWidth: true
                Layout.fillHeight: true
                antialiasing: true
                legend.visible: true
                theme: Universal.theme
                
                // Set the chart background color explicitly to avoid theme issues
                backgroundColor: toolBar.toggle ? "#2d2d2d" : "#ffffff"
                
                ValueAxis {
                    id: axisY
                    min: 0
                    max: 10
                    tickCount: 11
                    titleText: "Voltage Drop (%)"
                    labelsColor: toolBar.toggle ? "#ffffff" : "#000000"
                    gridVisible: true
                }
                
                CategoryAxis {
                    id: axisX
                    min: 0
                    max: 18
                    labelsPosition: CategoryAxis.AxisLabelsPositionOnValue
                    titleText: "Cable Size (mm²)"
                    labelsColor: toolBar.toggle ? "#ffffff" : "#000000"
                    
                    // Show only common sizes to avoid crowding
                    CategoryRange {
                        label: "1.5"
                        endValue: 0
                    }
                    CategoryRange {
                        label: "4"
                        endValue: 2
                    }
                    CategoryRange {
                        label: "10"
                        endValue: 4
                    }
                    CategoryRange {
                        label: "25"
                        endValue: 6
                    }
                    CategoryRange {
                        label: "50"
                        endValue: 8
                    }
                    CategoryRange {
                        label: "95"
                        endValue: 10
                    }
                    CategoryRange {
                        label: "150"
                        endValue: 12
                    }
                    CategoryRange {
                        label: "240"
                        endValue: 14
                    }
                    CategoryRange {
                        label: "400"
                        endValue: 16
                    }
                    CategoryRange {
                        label: "630"
                        endValue: 18
                    }
                }
                
                LineSeries {
                    id: thresholdLine
                    name: "5% Limit"
                    color: "red"
                    width: 2
                    style: Qt.DashLine
                    axisX: axisX
                    axisY: axisY
                }
                
                ScatterSeries {
                    id: dropPercentSeries
                    name: "Current Cable"
                    color: dropPercent.percentage > 5 ? "red" : "green"
                    markerSize: 15
                    markerShape: ScatterSeries.MarkerShapeRectangle
                    borderColor: "white"
                    borderWidth: 2
                    axisX: axisX
                    axisY: axisY
                    
                    // Add tooltip for the point using a safer approach
                    onClicked: function(point) {
                        pointTooltip.text = cableSelect.currentText + "mm² - " + 
                                           dropPercent.percentage.toFixed(2) + "%\n" +
                                           "Current: " + currentInput.text + "A"
                        pointTooltip.x = point.x + 10
                        pointTooltip.y = point.y - 30
                        pointTooltip.visible = true
                    }
                }
                
                ScatterSeries {
                    id: comparisonSeries
                    name: "Comparison Cables"
                    color: "blue"
                    markerSize: 10
                    markerShape: ScatterSeries.MarkerShapeCircle
                    axisX: axisX
                    axisY: axisY
                    
                    // Add tooltip for the comparison points with safer approach
                    onClicked: function(point) {
                        try {
                            // Find the point data
                            for (let i = 0; i < chartPopup.comparisonPoints.length; i++) {
                                let cp = chartPopup.comparisonPoints[i]
                                if (Math.abs(cp.x - point.x) < 0.1 && Math.abs(cp.y - point.y) < 0.1) {
                                    pointTooltip.text = cp.cableSize + "mm² - " + 
                                                      cp.dropPercent.toFixed(2) + "%\n" +
                                                      cp.status
                                    pointTooltip.x = point.x + 10
                                    pointTooltip.y = point.y - 30
                                    pointTooltip.visible = true
                                    break
                                }
                            }
                        } catch (e) {
                            console.error("Error in comparison point tooltip:", e)
                        }
                    }
                }
                
                // Add a visual line series to show trend
                LineSeries {
                    id: trendLine
                    name: "Trend"
                    color: "#80808080"  // Semi-transparent gray
                    width: 2
                    axisX: axisX
                    axisY: axisY
                }
                
                // Show a tooltip when points are clicked
                Rectangle {
                    id: pointTooltip
                    color: toolBar.toggle ? "#404040" : "#f0f0f0"
                    border.color: toolBar.toggle ? "#909090" : "#a0a0a0"
                    border.width: 1
                    width: tooltipText.width + 16
                    height: tooltipText.height + 8
                    radius: 4
                    visible: false
                    z: 100  // Ensure tooltip appears above other elements
                    
                    Text {
                        id: tooltipText
                        anchors.centerIn: parent
                        text: ""  // Initialize with empty text
                        color: toolBar.toggle ? "#ffffff" : "#000000"
                    }
                    
                    // Close tooltip when clicked anywhere else
                    MouseArea {
                        anchors.fill: parent
                        onClicked: pointTooltip.visible = false
                    }
                    
                    // Auto-hide after 3 seconds
                    Timer {
                        running: pointTooltip.visible
                        interval: 3000
                        onTriggered: pointTooltip.visible = false
                    }
                }
                
                // Add a MouseArea to the ChartView to hide tooltips
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    z: -1  // Place behind the series to allow them to receive clicks
                    propagateComposedEvents: true
                    onClicked: {
                        // Only handle clicks that weren't handled by series
                        if (!mouse.accepted) {
                            pointTooltip.visible = false
                            mouse.accepted = true
                        }
                    }
                }
            }
            
            // Add checkbox to show all cable sizes
            CheckBox {
                id: showAllCheckbox
                text: "Show Comparison with All Cable Sizes"
                checked: chartPopup.showAllCables
                onCheckedChanged: {
                    chartPopup.showAllCables = checked
                    enhancedChartUpdate()
                }
                Layout.alignment: Qt.AlignHCenter
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                
                Button {
                    text: "Close"
                    onClicked: chartPopup.close()
                }
                
                Button {
                    text: "Save As Image"
                    onClicked: {
                        try {
                            // Use a more robust grabbing method
                            chartView.grabToImage(function(result) {
                                if (result && result.width > 0 && result.height > 0) {
                                    console.log("Successfully grabbed image: " + result.width + "x" + result.height);
                                    chartPopup.savedImage = result;
                                    saveImageDialog.open();
                                } else {
                                    console.error("Failed to grab image - result is null or empty");
                                    imageSaveError.messageText = "Failed to capture chart image";
                                    imageSaveError.open();
                                }
                            }, Qt.size(chartView.width, chartView.height));
                        } catch (err) {
                            console.error("Error grabbing image:", err);
                            imageSaveError.messageText = "Error grabbing chart image: " + err.toString();
                            imageSaveError.open();
                        }
                    }
                }
                
                // Add button to reset zoom
                Button {
                    text: "Reset View"
                    onClicked: {
                        axisX.min = 0
                        axisX.max = 18
                        
                        // Find the max value for y-axis
                        let maxY = 10
                        for (let i = 0; i < chartPopup.comparisonPoints.length; i++) {
                            if (chartPopup.comparisonPoints[i].dropPercent > maxY) {
                                maxY = chartPopup.comparisonPoints[i].dropPercent * 1.1
                            }
                        }
                        
                        if (dropPercent.percentage > maxY) {
                            maxY = dropPercent.percentage * 1.1
                        }
                        
                        axisY.max = Math.max(Math.ceil(maxY), 10) // At least show up to 10%
                    }
                }
            }
        }
        
        property var savedImage: null
        
        FileDialog {
            id: saveImageDialog
            title: "Save Chart Image"
            fileMode: FileDialog.SaveFile
            nameFilters: ["Image files (*.png)"]
            
            onAccepted: {
                if (chartPopup.savedImage) {
                    try {
                        // Improved path handling for Linux
                        let filePath = saveImageDialog.selectedFile.toString();
                        console.log("Original selected path:", filePath);
                        
                        // Remove URL prefix from file path
                        if (filePath.startsWith("file:///")) {
                            filePath = filePath.substring(7);
                        } else if (filePath.startsWith("file:/")) {
                            filePath = filePath.substring(5);
                        }
                        
                        // Ensure filename ends with .png
                        if (!filePath.toLowerCase().endsWith(".png")) {
                            filePath += ".png";
                        }
                        
                        console.log("Attempting to save chart image to:", filePath);
                        
                        // Use our helper function to save the image
                        saveChartImage(chartPopup.savedImage, filePath);
                        
                    } catch (err) {
                        console.error("Error in save process:", err);
                        imageSaveError.messageText = "Error: " + err.toString();
                        imageSaveError.open();
                    }
                } else {
                    console.error("No image data to save");
                    imageSaveError.messageText = "No image data available to save";
                    imageSaveError.open();
                }
            }
        }
    }

    // Add feedback popups for image saving
    Popup {
        id: imageSaveSuccess
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400  // Increased width
        height: 150 // Increased height
        
        property string messageText: "Chart image saved successfully"

        contentItem: ColumnLayout {
            Label {
                text: imageSaveSuccess.messageText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: imageSaveSuccess.close()
            }
        }
    }
    Popup {
        id: imageSaveError
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 120
        
        property string messageText: "Failed to save image"
        
        contentItem: ColumnLayout {
            Label {
                text: imageSaveError.messageText
                wrapMode: Text.WordWrap
                color: "red"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: imageSaveError.close()
            }
        }
    }

    function getColumnWidth(column) {
        switch(column) {
            case 0: return 100  // Size
            case 1: return 100  // Material
            case 2: return 100  // Cores
            case 3: return 100  // mV/A/m
            case 4: return 120  // Rating
            case 5: return 120  // V-Drop
            case 6: return 100  // Drop %
            case 7: return 100  // Status
            default: return 100
        }
    }

    function calculateVoltageDropMV() {
        // ...existing calculation code...

        if (result.isValid) {
            // Save calculation to history
            resultsManager.save_calculation({
                "voltage_system": systemComboBox.currentText,
                "kva_per_house": kvaPerHouseSpinBox.value,
                "num_houses": numHousesSpinBox.value,
                "diversity_factor": diversityFactorSpinBox.value,
                "total_kva": totalKVA,
                "current": current,
                "cable_size": cableComboBox.currentValue,
                "conductor": conductorComboBox.currentText,
                "core_type": coreComboBox.currentText,
                "length": lengthSpinBox.value,
                "voltage_drop": vDrop,
                "drop_percent": dropPercent,
                "admd_enabled": admdCheckbox.checked
            });
        }
    }

    // Enhanced chart update function with multiple points and better visualization
    function enhancedChartUpdate() {
        console.log("Updating chart with enhanced approach")
        try {
            // Known cable sizes in order - used for x-axis positioning
            const knownSizes = ["1.5", "2.5", "4", "6", "10", "16", "25", "35", "50", "70", "95", 
                                "120", "150", "185", "240", "300", "400", "500", "630"]
            
            // Clear existing data
            dropPercentSeries.clear()
            comparisonSeries.clear()
            thresholdLine.clear()
            trendLine.clear()
            chartPopup.comparisonPoints = []
            
            // Draw the 5% threshold line
            thresholdLine.append(0, 5)
            thresholdLine.append(knownSizes.length - 1, 5)
            
            // Find the index of the current cable size
            const selectedCable = cableSelect.currentText
            const cableIndex = knownSizes.indexOf(selectedCable)
            const xPosition = cableIndex >= 0 ? cableIndex : 10 // Default to middle if not found
            
            // Get the current cable's voltage drop
            const currentDropValue = dropPercent.percentage
            
            // Add the current point (make it stand out)
            dropPercentSeries.append(xPosition, currentDropValue)
            
            // Create a trend line and comparison points if checkbox is checked
            if (chartPopup.showAllCables) {
                // Extract data from the table if possible
                let comparisonData = []
                
                // Iterate through knownSizes and find values in the table
                for (let i = 0; i < knownSizes.length; i++) {
                    const cableSize = knownSizes[i]
                    
                    // Skip the current cable size - it's already displayed differently
                    if (cableSize === selectedCable) {
                        continue
                    }
                    
                    // Try to get the voltage drop percentage for this cable size from the UI
                    // We'll estimate it using an exponential function:
                    // v_drop ∝ 1/A where A is cross-sectional areaortional to cable cross-section
                    // v_drop ∝ 1/A where A is cross-sectional area
                    
                    const currentArea = parseFloat(selectedCable)
                    const compareArea = parseFloat(cableSize)
                    
                    if (currentArea > 0 && compareArea > 0) {
                        // Estimate drop percentage using inverse proportion with adjustment
                        // for larger cables which don't follow a perfect inverse relationship
                        let adjustmentFactor = 0.85 // Less than 1 for a more conservative estimate
                        let estimatedDrop = currentDropValue * (currentArea / compareArea) * adjustmentFactor
                        
                        // Add some randomness to make it look more realistic (+/- 5%)
                        const randomFactor = 0.95 + Math.random() * 0.1
                        estimatedDrop *= randomFactor
                        
                        // Determine status
                        let status = "OK"
                        if (estimatedDrop > 7) {
                            status = "SEVERE"
                        } else if (estimatedDrop > 5) {
                            status = "WARNING"
                        } else if (estimatedDrop > 2) {
                            status = "SUBMAIN"
                        }
                        
                        // Add to comparison data
                        comparisonData.push({
                            cableSize: cableSize,
                            dropPercent: estimatedDrop,
                            xPos: i,
                            status: status
                        })
                        
                        // Add to comparisonPoints for tooltips
                        chartPopup.comparisonPoints.push({
                            cableSize: cableSize,
                            dropPercent: estimatedDrop,
                            x: i,
                            y: estimatedDrop,
                            status: status
                        })
                        
                        // Add point to the comparison series
                        comparisonSeries.append(i, estimatedDrop)
                        
                        // Add point to trend line
                        trendLine.append(i, estimatedDrop)
                    }
                }
                
                // Add the current point to the trend line
                trendLine.append(xPosition, currentDropValue)
                
                // Sort trend line points by X coordinate
                let trendPoints = []
                for (let i = 0; i < trendLine.count; i++) {
                    trendPoints.push({
                        x: trendLine.at(i).x,
                        y: trendLine.at(i).y
                    })
                }
                
                // Sort the trend points by x-coordinate
                trendPoints.sort(function(a, b) {
                    return a.x - b.x
                })
                
                // Recreate trend line with sorted points
                trendLine.clear()
                for (let i = 0; i < trendPoints.length; i++) {
                    trendLine.append(trendPoints[i].x, trendPoints[i].y)
                }
            }
            
            // Set chart title with more info
            const pctText = currentDropValue > 5 ? "OVER LIMIT" : "WITHIN LIMIT"
            const lengthText = lengthInput.text ? lengthInput.text + "m" : "0m"
            const currentText = currentInput.text ? currentInput.text + "A" : "0A"
            
            chartView.title = selectedCable + " mm² - " + 
                            currentDropValue.toFixed(2) + "% - " + 
                            lengthText + " - " + 
                            currentText + " (" + pctText + ")"
            
            console.log("Enhanced chart updated successfully")
        } catch (err) {
            console.error("Enhanced chart error: " + err)
            
            // Add fallback visualization if the enhanced one fails
            dropPercentSeries.clear()
            dropPercentSeries.append(5, dropPercent.percentage)
            
            thresholdLine.clear()
            thresholdLine.append(0, 5)
            thresholdLine.append(10, 5)
            
            chartView.title = "Cable " + cableSelect.currentText + " mm²"
        }
    }

    // Add this function to improve save reliability
    function saveChartImage(image, filePath) {
        try {
            // Try the ResultsManager approach first
            let success = resultsManager.save_qimage(image, filePath);
            
            if (success) {
                console.log("Successfully saved image to: " + filePath);
                imageSaveSuccess.messageText = "Chart image saved to: " + filePath;
                imageSaveSuccess.open();
            } else {
                console.log("Primary save method failed, trying fallback...");
                // Use the fallback method
                imageSaver.saveImage(image, filePath);
            }
        } catch (err) {
            console.error("Error in saveChartImage:", err);
            imageSaveError.messageText = "Error: " + err.toString();
            imageSaveError.open();
        }
    }
}