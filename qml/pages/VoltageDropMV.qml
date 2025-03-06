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
    
Page {
    id: root
    padding: 0

    // Move model to top level and create explicit binding
    property real currentVoltageDropValue: voltageDropMV.voltageDrop || 0

    VoltageDropMV {
        id: voltageDropMV
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
                        Layout.minimumHeight: 520
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
                                currentIndex: 0
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
                                currentIndex: 0
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
                                currentIndex: 0  // Set default selection
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
                                placeholderText: "Enter length"
                                onTextChanged: voltageDropMV.setLength(parseFloat(text))
                                Layout.fillWidth: true
                                validator: DoubleValidator { bottom: 0 }
                            }

                            Label { text: "Installation Method:" }
                            ComboBox {
                                model: voltageDropMV.installationMethods
                                onCurrentTextChanged: voltageDropMV.setInstallationMethod(currentText)
                                Layout.fillWidth: true
                            }

                            Label { text: "Temperature (°C):" }
                            TextField {
                                text: "75"
                                onTextChanged: voltageDropMV.setTemperature(parseFloat(text))
                                Layout.fillWidth: true
                                validator: DoubleValidator { bottom: 0; top: 120 }
                            }

                            Label { text: "Grouping Factor:" }
                            TextField {
                                text: "1.0"
                                onTextChanged: voltageDropMV.setGroupingFactor(parseFloat(text))
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

                            
                        }
                    }

                    WaveCard {
                        title: "Results"
                        Layout.minimumHeight: 280
                        Layout.minimumWidth:400
                        showInfo: false

                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            rowSpacing: 18

                            // Label {
                            //     text: "Total Adjusted Load: " + 
                            //         ((parseFloat(kvaPerHouseInput.text) || 0) * 
                            //         (parseInt(numberOfHousesInput.text) || 0) * 
                            //         voltageDropMV.diversityFactor).toFixed(1) + " kVA"
                            //     font.pixelSize: 16
                            //     font.weight: Font.Medium
                            // }

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
                        }
                    }
                }

                WaveCard {
                    title: "Cable Size Comparison"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    showInfo: false

                    ColumnLayout {
                        anchors.fill: parent

                        // Header row
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: toolBar.toggle ? "#424242" : "#e0e0e0"

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
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                            color: toolBar.toggle ? "#ffffff" : "#000000"
                                        }
                                    }
                                }
                            }
                        }

                        // Table content
                        TableView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: voltageDropMV.tableModel

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