import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import '../components'

import VDropMV 1.0
import Results 1.0  // Add this import

Page {
    id: root
    padding: 0

    // Move model to top level and create explicit binding
    property real currentVoltageDropValue: voltageDropMV.voltageDrop || 0

    VoltageDropMV {
        id: voltageDropMV
    }

    ResultsManager {
        id: resultsManager
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
                                    dropValue.text = "0.00 V"
                                    dropPercent.text = "0.00%"
                                    
                                    // Reset model state
                                    voltageDropMV.reset()
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
                                property real percentage: root.currentVoltageDropValue / voltageDropMV.selectedVoltage.slice(0, -1) * 100
                                text: percentage.toFixed(2) + "%"
                                color: percentage > 5 ? "red" : "green"
                            }

                            Label { text: "Diversity Factor Applied: " }

                            Label {
                                text:  voltageDropMV.diversityFactor.toFixed(2)
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
                                    onClicked: voltageDropMV.saveCurrentCalculation()
                                }

                                Button {
                                    text: "Show Details"
                                    icon.name: "Info"
                                    enabled: root.currentVoltageDropValue > 0
                                    onClicked: resultsPopup.open()
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
}