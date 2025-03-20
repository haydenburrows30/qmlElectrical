import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"  // Import for WaveCard component

Item {
    id: transformerLineSection
    
    // Properties passed from parent
    property var calculator
    property bool calculatorReady
    property real totalGeneratedPower
    property var safeValueFunction
    
    // Signal for when calculation is requested
    signal calculate()

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 40
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                ColumnLayout {
                    Layout.maximumWidth: 400
                    Layout.minimumWidth: 400
                    
                    Layout.alignment: Qt.AlignTop
            
                    // Transformer parameters section
                    WaveCard {
                        title: "Transformer Parameters (400V to 11kV)"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10
                            
                            Label { text: "Transformer Rating (kVA):" }
                            SpinBox {
                                id: transformerRatingSpinBox
                                from: 100
                                to: 5000
                                value: calculatorReady ? calculator.transformerRating : 1000
                                stepSize: 50
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: if (calculatorReady) calculator.setTransformerRating(value)
                            }
                            
                            Label { text: "Transformer Impedance (%):" }
                            SpinBox {
                                id: transformerImpedanceSpinBox
                                from: 30
                                to: 100
                                value: calculatorReady ? calculator.transformerImpedance * 10 : 60
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 10.0
                                
                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setTransformerImpedance(realValue)
                            }
                            
                            Label { text: "Transformer X/R Ratio:" }
                            SpinBox {
                                id: transformerXRRatioSpinBox
                                from: 30
                                to: 150
                                value: calculatorReady ? calculator.transformerXRRatio * 10 : 80
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 10.0
                                
                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setTransformerXRRatio(realValue)
                            }
                        }
                    }
                    
                    // Line parameters section
                    WaveCard {
                        title: "Line Parameters (5km Cable)"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10
                            
                            Label { text: "Line Length (km):" }
                            SpinBox {
                                id: lineLengthSpinBox
                                from: 1
                                to: 50
                                value: calculatorReady ? calculator.lineLength * 10 : 50
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 10.0
                                
                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setLineLength(realValue)
                            }
                            
                            Label { text: "Line Resistance (Ohm/km):" }
                            SpinBox {
                                id: lineRSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.lineR * 100 : 25
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100.0
                                
                                textFromValue: function(value) {
                                    return (value / 100.0).toFixed(2);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setLineR(realValue)
                            }
                            
                            Label { text: "Line Reactance (Ohm/km):" }
                            SpinBox {
                                id: lineXSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.lineX * 100 : 20
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100.0
                                
                                textFromValue: function(value) {
                                    return (value / 100.0).toFixed(2);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setLineX(realValue)
                            }
                        }
                    }
                    
                    // Load parameters updated by wind turbine output
                    WaveCard {
                        title: "Load Parameters (From Wind Turbine Output)"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10
                            
                            Label { text: "Wind Turbine Output (MW):" }
                            TextField {
                                readOnly: true
                                Layout.fillWidth: true
                                text: (totalGeneratedPower / 1000).toFixed(3)
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Power Factor:" }
                            SpinBox {
                                id: loadPowerFactorSpinBox
                                from: 70
                                to: 100
                                value: calculatorReady ? calculator.loadPowerFactor * 100 : 95
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100.0
                                
                                textFromValue: function(value) {
                                    return (value / 100.0).toFixed(2);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setLoadPowerFactor(realValue)
                            }
                            
                            Button {
                                text: "Calculate System"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: calculate()
                            }
                        }
                    }
                    
                    // Add Voltage Regulator parameters section
                    WaveCard {
                        title: "Voltage Regulator"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 420  // Increased height for additional parameters
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10
                            
                            // Enable/disable regulator
                            Label { text: "Enable Voltage Regulator:" }
                            Switch {
                                id: regulatorEnabledSwitch
                                checked: calculatorReady ? calculator.voltageRegulatorEnabled : true
                                onToggled: if (calculatorReady) calculator.setVoltageRegulatorEnabled(checked)
                            }
                            
                            // Regulator type - specific to Eaton
                            Label { text: "Regulator Type:" }
                            TextField {
                                id: regulatorTypeText
                                text: "Eaton Single-Phase"
                                readOnly: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                background: Rectangle {
                                    color: "#f0f0f0"
                                    border.color: "#c0c0c0"
                                    radius: 2
                                }
                            }
                            
                            // Regulator model - specific to VR-32
                            Label { text: "Regulator Model:" }
                            TextField {
                                id: regulatorModelText
                                text: "Cooper VR-32"
                                readOnly: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                background: Rectangle {
                                    color: "#f0f0f0"
                                    border.color: "#c0c0c0"
                                    radius: 2
                                }
                            }
                            
                            // Connection type - delta
                            Label { text: "Connection Type:" }
                            TextField {
                                id: regulatorConnectionText
                                text: "Delta"
                                readOnly: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                background: Rectangle {
                                    color: "#f0f0f0"
                                    border.color: "#c0c0c0"
                                    radius: 2
                                }
                            }
                            
                            // Capacity per phase
                            Label { text: "Capacity per Phase (kVA):" }
                            TextField {
                                id: regulatorCapacityText
                                text: "185"
                                readOnly: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                background: Rectangle {
                                    color: "#f0f0f0"
                                    border.color: "#c0c0c0"
                                    radius: 2
                                }
                            }
                            
                            // Target voltage setting
                            Label { text: "Target Voltage (kV):" }
                            SpinBox {
                                id: regulatorTargetSpinBox
                                from: 100
                                to: 120
                                value: calculatorReady ? calculator.voltageRegulatorTarget * 10 : 110
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                property real realValue: value / 10.0
                                
                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setVoltageRegulatorTarget(realValue)
                            }
                            
                            // Bandwidth
                            Label { text: "Bandwidth (%):" }
                            SpinBox {
                                id: regulatorBandwidthSpinBox
                                from: 10
                                to: 50
                                value: calculatorReady ? calculator.voltageRegulatorBandwidth * 10 : 20
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                property real realValue: value / 10.0
                                
                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setVoltageRegulatorBandwidth(realValue)
                            }
                            
                            // Regulator range
                            Label { text: "Range (±%):" }
                            SpinBox {
                                id: regulatorRangeSpinBox
                                from: 50
                                to: 150
                                value: calculatorReady ? calculator.voltageRegulatorRange * 10 : 100
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                property real realValue: value / 10.0
                                
                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setVoltageRegulatorRange(realValue)
                            }
                            
                            // Number of steps
                            Label { text: "Number of Steps:" }
                            TextField {
                                id: regulatorStepsText
                                text: "32"
                                readOnly: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                background: Rectangle {
                                    color: "#f0f0f0"
                                    border.color: "#c0c0c0"
                                    radius: 2
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignTop

                    ColumnLayout {
                        Layout.minimumWidth: 400
                        Layout.maximumWidth: 400
                        

                        // System results section
                        WaveCard {
                            title: "Electrical System Results"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            
                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 10
                                
                                Label { text: "Transformer Z (Ohms):" }
                                TextField {
                                    id: transformerZOhmsText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.transformerZOhms, 0).toFixed(3) : "0.000"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Transformer R (Ohms):" }
                                TextField {
                                    id: transformerROhmsText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.transformerROhms, 0).toFixed(3) : "0.000"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Transformer X (Ohms):" }
                                TextField {
                                    id: transformerXOhmsText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.transformerXOhms, 0).toFixed(3) : "0.000"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Line Total Z (Ohms):" }
                                TextField {
                                    id: lineTotalZText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.lineTotalZ, 0).toFixed(3) : "0.000"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Voltage Drop (%):" }
                                TextField {
                                    id: voltageDropText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.voltageDrop, 0).toFixed(2) : "0.00"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Fault Current at LV Side (kA):" }
                                TextField {
                                    id: faultCurrentLVText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.faultCurrentLV, 0).toFixed(2) : "0.00"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Fault Current at HV Side (kA):" }
                                TextField {
                                    id: faultCurrentHVText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.faultCurrentHV, 0).toFixed(2) : "0.00"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                            }
                        }
                        
                        // Transformer protection section
                        WaveCard {
                            title: "Transformer Protection Settings"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 230
                            
                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 10
                                
                                Label { text: "Relay Pickup Current (A):" }
                                TextField {
                                    id: relayPickupCurrentText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "CT Ratio:" }
                                TextField {
                                    id: relayCtRatioText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? calculator.relayCtRatio : "300/1"  // Updated default value
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Relay Curve Type:" }
                                TextField {
                                    id: relayCurveTypeText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? calculator.relayCurveType : "Very Inverse"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Time Dial Setting:" }
                                TextField {
                                    id: relayTimeDialText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.relayTimeDial, 0).toFixed(2) : "0.30"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.minimumWidth: 400
                        Layout.maximumWidth: 400
                        Layout.alignment: Qt.AlignTop
                                        
                        // Cable selection guide
                        WaveCard {
                            title: "Cable Selection Guide for Wind Turbine Connection"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            Layout.alignment: Qt.AlignTop
                            
                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 10
                                
                                Label { text: "Recommended HV Cable Size:" }
                                TextField {
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: {
                                        // Calculate based on load MVA
                                        var currentHV = (totalGeneratedPower / 1000 * 1000) / (Math.sqrt(3) * 11)
                                        
                                        if (currentHV < 30) return "25 mm²"
                                        else if (currentHV < 50) return "35 mm²"
                                        else if (currentHV < 70) return "50 mm²"
                                        else if (currentHV < 90) return "70 mm²"
                                        else if (currentHV < 120) return "95 mm²" 
                                        else return "120 mm² or larger"
                                    }
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Recommended LV Cable Size:" }
                                TextField {
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: {
                                        // Calculate based on generator output
                                        var currentLV = (totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)
                                        
                                        if (currentLV < 100) return "25 mm²"
                                        else if (currentLV < 150) return "50 mm²"
                                        else if (currentLV < 200) return "70 mm²"
                                        else if (currentLV < 250) return "95 mm²"
                                        else if (currentLV < 300) return "120 mm²"
                                        else return "150 mm² or larger"
                                    }
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                            }
                        }
                        
                        // Add regulator results section
                        WaveCard {
                            title: "Voltage Regulation Results"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 250
                            visible: regulatorEnabledSwitch.checked
                            Layout.alignment: Qt.AlignTop
                            
                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 10
                                
                                Label { text: "Unregulated Voltage (kV):" }
                                TextField {
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? 
                                        ((11 * (1 - safeValueFunction(calculator.voltageDrop, 0) / 100))).toFixed(2) : 
                                        "0.00"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Regulated Voltage (kV):" }
                                TextField {
                                    id: regulatedVoltageText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.regulatedVoltage, 0).toFixed(2) : "0.00"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Tap Position:" }
                                TextField {
                                    id: regulatorTapPositionText
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.regulatorTapPosition, 0).toString() : "0"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Step Size (%):" }
                                TextField {
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: (calculator.voltageRegulatorRange / 16).toFixed(3)
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                                
                                Label { text: "Total 3-Phase Capacity (kVA):" }
                                TextField {
                                    readOnly: true
                                    Layout.fillWidth: true
                                    text: calculatorReady ? safeValueFunction(calculator.regulatorThreePhaseCapacity, 0).toFixed(0) : "555"
                                    background: Rectangle {
                                        color: "#e8f6ff"
                                        border.color: "#0078d7"
                                        radius: 2
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                }
                // Spacer to push content to the top
            }
        }
    }
    
    // Direct property binding instead of signals
    Timer {
        id: updateTimer
        interval: 250
        repeat: true
        running: calculatorReady
        onTriggered: {
            if(calculatorReady) {
                updateDisplayValues()
            }
        }
        
        function updateDisplayValues() {
            // Update transformer/line values
            transformerZOhmsText.text = safeValueFunction(calculator.transformerZOhms, 0).toFixed(3)
            transformerROhmsText.text = safeValueFunction(calculator.transformerROhms, 0).toFixed(3)
            transformerXOhmsText.text = safeValueFunction(calculator.transformerXOhms, 0).toFixed(3)
            lineTotalZText.text = safeValueFunction(calculator.lineTotalZ, 0).toFixed(3)
            voltageDropText.text = safeValueFunction(calculator.voltageDrop, 0).toFixed(2)
            faultCurrentLVText.text = safeValueFunction(calculator.faultCurrentLV, 0).toFixed(2)
            faultCurrentHVText.text = safeValueFunction(calculator.faultCurrentHV, 0).toFixed(2)
            
            // Update protection settings
            relayPickupCurrentText.text = safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2)
            relayTimeDialText.text = safeValueFunction(calculator.relayTimeDial, 0).toFixed(2)
            relayCtRatioText.text = calculator.relayCtRatio
            relayCurveTypeText.text = calculator.relayCurveType
            
            // Update regulator values
            if (calculatorReady) {
                regulatedVoltageText.text = safeValueFunction(calculator.regulatedVoltage, 0).toFixed(2)
                regulatorTapPositionText.text = safeValueFunction(calculator.regulatorTapPosition, 0).toString()
            }
        }
    }
}
