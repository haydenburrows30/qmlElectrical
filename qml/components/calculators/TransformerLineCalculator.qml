import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../visualizers"
import "../style"
import "../popups"

import TransformerLine 1.0

Item {
    id: root

    property var calculator

    property bool calculatorReady: calculator !== null
    
    Component.onCompleted: {
        // Create the calculator instance when component is loaded
        calculator = Qt.createQmlObject('import QtQuick; import TransformerLine 1.0; TransformerLineCalculator {}', root, "dynamicCalculator");
    }
    
    function safeValue(value, defaultVal) {
        if (value === undefined || value === null) {
            return defaultVal;
        }
        
        if (typeof value !== 'number' || isNaN(value) || !isFinite(value)) {
            return defaultVal;
        }
        
        return value;
    }

    PopUpText {
        parentCard: results
        popupText: "<b>Protection Settings Notes:</b><br>" +
                            "• Relay pickup is set at 120% of transformer rated current<br>" +
                            "• CT ratio is selected based on the pickup current<br>" +
                            "• Very Inverse curve is recommended for transformer protection<br>" +
                            "• Time dial setting depends on coordination with upstream and downstream devices<br>" +
                            "• Actual settings should be confirmed with a coordination study<br><br>" +
                            "<b>Recommended Additional Protection:</b><br>" +
                            "• Differential protection for transformer > 5 MVA<br>" +
                            "• Earth fault protection (typically 10-20% of CT primary rating)<br>" +
                            "• Restricted Earth Fault (REF) protection<br>" +
                            "• Thermal overload protection<br>" +
                            "• Buchholz relay for oil-filled transformers<br>" +
                            "• Standby earth fault protection for the cable<br><br>" +
                            "<b>Cable Selection Considerations:</b><br>" +
                            "• Cable should be rated for at least 125% of full load current<br>" +
                            "• Voltage drop should typically be kept below 5%<br>" +
                            "• Cable must withstand fault current for protection clearing time<br>" +
                            "• Standard 11kV cables include: 3-core XLPE with copper or aluminum conductors<br>" +
                            "• Typical sizes for 1000 kVA transformer: 70-120 mm² depending on installation conditions"
    }

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent
       
        TransformerLineViz {}

        RowLayout {
            ColumnLayout {
                Layout.minimumWidth: 300
                Layout.alignment: Qt.AlignTop
    
                // Transformer parameters section
                WaveCard {
                    id: results
                    title: "Transformer Parameters (400V to 11kV)"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 180

                    showSettings: true
                    
                    GridLayout {
                        columns: 2
                        
                        Label { text: "Transformer Rating (kVA):" ; Layout.minimumWidth: 200}
                        SpinBoxRound {
                            id: transformerRatingSpinBox
                            from: 100
                            to: 5000
                            value: calculator ? calculator.transformerRating : 300
                            stepSize: 50
                            editable: true
                            Layout.minimumWidth: 150
                            onValueModified: if (calculatorReady) calculator.setTransformerRating(value)
                        }
                        
                        Label { text: "Transformer Impedance (%):" }
                        SpinBoxRound {
                            id: transformerImpedanceSpinBox
                            from: 30
                            to: 100
                            value: calculator ? calculator.transformerImpedance * 10 : 60
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
                        SpinBoxRound {
                            id: transformerXRRatioSpinBox
                            from: 30
                            to: 150
                            value: calculator ? calculator.transformerXRRatio * 10 : 80
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
                    Layout.minimumHeight: 180
                    
                    GridLayout {
                        columns: 2
                        
                        Label { text: "Line Length (km):" ; Layout.minimumWidth: 200}
                        SpinBoxRound {
                            id: lineLengthSpinBox
                            from: 1
                            to: 50
                            value: calculator ? calculator.lineLength * 10 : 50
                            stepSize: 5
                            editable: true
                            Layout.minimumWidth: 150
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
                        SpinBoxRound {
                            id: lineRSpinBox
                            from: 1
                            to: 100
                            value: calculator ? calculator.lineR * 100 : 25
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
                        SpinBoxRound {
                            id: lineXSpinBox
                            from: 1
                            to: 100
                            value: calculator ? calculator.lineX * 100 : 20
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
                
                // Load parameters section
                WaveCard {
                    title: "Load Parameters"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 150
                    
                    GridLayout {
                        columns: 2
                        
                        Label { text: "Load (MVA):" ; Layout.minimumWidth: 200}
                        SpinBoxRound {
                            id: loadMVASpinBox
                            from: 1
                            to: 100
                            value: calculator ? calculator.loadMVA * 10 : 8
                            stepSize: 1
                            editable: true
                            Layout.minimumWidth: 150
                            property real realValue: value / 10.0
                            
                            textFromValue: function(value) {
                                return (value / 10.0).toFixed(1);
                            }
                            
                            valueFromText: function(text) {
                                return Math.round(parseFloat(text) * 10);
                            }
                            
                            onValueModified: {
                                if (calculatorReady) calculator.setLoadMVA(realValue)
                                calculator.refreshCalculations()
                            }
                        }
                        
                        Label { text: "Power Factor:" }
                        SpinBoxRound {
                            id: loadPowerFactorSpinBox
                            from: 70
                            to: 100
                            value: calculator ? calculator.loadPowerFactor * 100 : 85
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
                    }
                }
            }

            ColumnLayout {
                Layout.minimumWidth: 300

                // System results section
                WaveCard {
                    title: "System Calculation Results"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 320
                    
                    GridLayout {
                        columns: 2
                        
                        Label { text: "Transformer Z (Ohms):" ; Layout.minimumWidth: 200}
                        TextFieldBlue {
                            id: transformerZOhmsText
                            Layout.minimumWidth: 150
                            text: calculatorReady ? safeValue(calculator.transformerZOhms, 0).toFixed(3) : "0.000"
                        }
                        
                        Label { text: "Transformer R (Ohms):" }
                        TextFieldBlue {
                            id: transformerROhmsText
                            text: calculatorReady ? safeValue(calculator.transformerROhms, 0).toFixed(3) : "0.000"
                        }
                        
                        Label { text: "Transformer X (Ohms):" }
                        TextFieldBlue {
                            id: transformerXOhmsText
                            text: calculatorReady ? safeValue(calculator.transformerXOhms, 0).toFixed(3) : "0.000"
                        }
                        
                        Label { text: "Line Total Z (Ohms):" }
                        TextFieldBlue {
                            id: lineTotalZText
                            text: calculatorReady ? safeValue(calculator.lineTotalZ, 0).toFixed(3) : "0.000"
                        }
                        
                        Label { text: "Voltage Drop (%):" }
                        TextFieldBlue {
                            id: voltageDropText
                            text: calculatorReady ? safeValue(calculator.voltageDrop, 0).toFixed(2) : "0.00"
                        }
                        
                        Label { text: "Fault Current at LV Side (kA):" }
                        TextFieldBlue {
                            id: faultCurrentLVText
                            text: calculatorReady ? safeValue(calculator.faultCurrentLV, 0).toFixed(2) : "0.00"
                        }
                        
                        Label { text: "Fault Current at HV Side (kA):" }
                        TextFieldBlue {
                            id: faultCurrentHVText
                            text: calculatorReady ? safeValue(calculator.faultCurrentHV, 0).toFixed(2) : "0.00"
                        }
                    }
                }
                
                // Protection parameters section
                WaveCard {
                    title: "Protection Settings"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 210
                    
                    GridLayout {
                        columns: 2
                        
                        Label { text: "Relay Pickup Current (A):" ; Layout.minimumWidth: 200}
                        TextFieldBlue {
                            Layout.minimumWidth: 150
                            text: calculatorReady ? safeValue(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
                        }
                        
                        Label { text: "CT Ratio:" }
                        TextFieldBlue {
                            id: relayCtRatioText
                            text: calculatorReady ? calculator.relayCtRatio : "300/5"
                        }
                        
                        Label { text: "Relay Curve Type:" }
                        TextFieldBlue {
                            id: relayCurveTypeText
                            text: calculatorReady ? calculator.relayCurveType : "Very Inverse"
                        }
                        
                        Label { text: "Time Dial Setting:" }
                        TextFieldBlue {
                            id: relayTimeDialText
                            text: calculatorReady ? safeValue(calculator.relayTimeDial, 0).toFixed(2) : "0.30"
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: calculator
        function calculationCompleted() {
            if (calculatorReady) {
                transformerZOhmsText.text = safeValue(calculator.transformerZOhms, 0).toFixed(3)
                transformerROhmsText.text = safeValue(calculator.transformerROhms, 0).toFixed(3)
                transformerXOhmsText.text = safeValue(calculator.transformerXOhms, 0).toFixed(3)
                lineTotalZText.text = safeValue(calculator.lineTotalZ, 0).toFixed(3)
                voltageDropText.text = safeValue(calculator.voltageDrop, 0).toFixed(2)
                faultCurrentLVText.text = safeValue(calculator.faultCurrentLV, 0).toFixed(2)
                faultCurrentHVText.text = safeValue(calculator.faultCurrentHV, 0).toFixed(2)
                relayPickupCurrentText.text = safeValue(calculator.relayPickupCurrent, 0).toFixed(2)
                relayTimeDialText.text = safeValue(calculator.relayTimeDial, 0).toFixed(2)
                relayCtRatioText.text = calculator.relayCtRatio
                relayCurveTypeText.text = calculator.relayCurveType
            }
        }
    }
}
