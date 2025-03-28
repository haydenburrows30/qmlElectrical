import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../visualizers"
import "../style"
import "../backgrounds"

import TransformerLine 1.0

Item {
    id: root
    anchors.fill: parent

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

    Popup {
        id: tipsPopup
        width: 600
        height: 400
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        ColumnLayout {
                width: parent.width
                spacing: Style.spacing
                
                Text {
                    text: "<b>Protection Settings Notes:</b><br>" +
                            "• Relay pickup is set at 120% of transformer rated current<br>" +
                            "• CT ratio is selected based on the pickup current<br>" +
                            "• Very Inverse curve is recommended for transformer protection<br>" +
                            "• Time dial setting depends on coordination with upstream and downstream devices<br>" +
                            "• Actual settings should be confirmed with a coordination study"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Text {
                    text: "<b>Recommended Additional Protection:</b><br>" +
                            "• Differential protection for transformer > 5 MVA<br>" +
                            "• Earth fault protection (typically 10-20% of CT primary rating)<br>" +
                            "• Restricted Earth Fault (REF) protection<br>" +
                            "• Thermal overload protection<br>" +
                            "• Buchholz relay for oil-filled transformers<br>" +
                            "• Standby earth fault protection for the cable"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Text {
                    text: "<b>Cable Selection Considerations:</b><br>" +
                            "• Cable should be rated for at least 125% of full load current<br>" +
                            "• Voltage drop should typically be kept below 5%<br>" +
                            "• Cable must withstand fault current for protection clearing time<br>" +
                            "• Standard 11kV cables include: 3-core XLPE with copper or aluminum conductors<br>" +
                            "• Typical sizes for 1000 kVA transformer: 70-120 mm² depending on installation conditions"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
    }

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: Style.spacing
       
        TransformerLineViz {

        }

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
                        columnSpacing: 10
                        rowSpacing: 10
                        
                        Label { text: "Transformer Rating (kVA):" ; Layout.minimumWidth: 200}
                        SpinBox {
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
                        SpinBox {
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
                        SpinBox {
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
                        columnSpacing: 10
                        rowSpacing: 10
                        
                        Label { text: "Line Length (km):" ; Layout.minimumWidth: 200}
                        SpinBox {
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
                        SpinBox {
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
                        SpinBox {
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
                        columnSpacing: 10
                        rowSpacing: 10
                        
                        Label { text: "Load (MVA):" ; Layout.minimumWidth: 200}
                        SpinBox {
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
                        SpinBox {
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
                    Layout.minimumHeight: 350
                    
                    GridLayout {
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10
                        
                        Label { text: "Transformer Z (Ohms):" ; Layout.minimumWidth: 200}
                        TextField {
                            id: transformerZOhmsText
                            readOnly: true
                            Layout.minimumWidth: 150
                            text: calculatorReady ? safeValue(calculator.transformerZOhms, 0).toFixed(3) : "0.000"
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
                            text: calculatorReady ? safeValue(calculator.transformerROhms, 0).toFixed(3) : "0.000"
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
                            text: calculatorReady ? safeValue(calculator.transformerXOhms, 0).toFixed(3) : "0.000"
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
                            text: calculatorReady ? safeValue(calculator.lineTotalZ, 0).toFixed(3) : "0.000"
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
                            text: calculatorReady ? safeValue(calculator.voltageDrop, 0).toFixed(2) : "0.00"
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
                            text: calculatorReady ? safeValue(calculator.faultCurrentLV, 0).toFixed(2) : "0.00"
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
                            text: calculatorReady ? safeValue(calculator.faultCurrentHV, 0).toFixed(2) : "0.00"
                            background: Rectangle {
                                color: "#e8f6ff"
                                border.color: "#0078d7"
                                radius: 2
                            }
                        }
                    }
                }
                
                // Protection parameters section
                WaveCard {
                    title: "Protection Settings"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 230
                    
                    GridLayout {
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10
                        
                        Label { text: "Relay Pickup Current (A):" ; Layout.minimumWidth: 200}
                        TextField {
                            id: relayPickupCurrentText
                            readOnly: true
                            ; Layout.minimumWidth: 150
                            text: calculatorReady ? safeValue(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
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
                            text: calculatorReady ? calculator.relayCtRatio : "300/5"
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
                            text: calculatorReady ? safeValue(calculator.relayTimeDial, 0).toFixed(2) : "0.30"
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
