import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"
import "../visualizers"
import "../backgrounds"
import "../style"
import "../backgrounds"



import OhmsLaw 1.0

Item {
    id: root

    property OhmsLawCalculator calculator: OhmsLawCalculator {}
    property bool calculatorReady: calculator !== null

    FontLoader {
        id: iconFont
        source: "../../../icons/MaterialIcons-Regular.ttf"
    }

    function calculateOhmsLaw() {
        if (!calculatorReady) return;
        
        let value1 = parseFloat(param1Value.text);
        let value2 = parseFloat(param2Value.text);
        
        if (isNaN(value1) || isNaN(value2)) return;

        const calculationMap = {
            "0_1": calculator.calculateFromVI,
            "0_2": calculator.calculateFromVR,
            "0_3": calculator.calculateFromVP,
            "1_2": calculator.calculateFromIR,
            "1_3": calculator.calculateFromIP,
            "2_3": calculator.calculateFromRP
        };
        
        const key = selectedParam1.currentIndex + "_" + selectedParam2.currentIndex;
        const calcFunction = calculationMap[key];
        
        if (calcFunction) {
            calcFunction(value1, value2);
        }
    }
    
    function updateVisualization() {
        ohmsLawCanvas.requestPaint();
    }

    Popup {
        id: tipsPopup
        width: 600
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
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.spacing
            width: parent.width
            
            
            Text {
                text: "<b>Basic Ohm's Law Equations:</b>"
                font.pixelSize: 14
            }
            
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: Style.spacing
                
                Text { text: "Voltage (V):" }
                Text { text: "V = I × R" }
                
                Text { text: "Current (I):" }
                Text { text: "I = V / R" }
                
                Text { text: "Resistance (R):" }
                Text { text: "R = V / I" }
                
                Text { text: "Power (P):" }
                Text { text: "P = V × I = I² × R = V² / R" }
            }
            
            Text {
                text: "<b>Applications:</b>"
                font.pixelSize: 14
                Layout.topMargin: 10
            }
            
            Text {
                text: "Ohm's Law is the foundation of electrical engineering and is used for circuit analysis, " +
                    "component selection, power calculations, fuse and circuit protection sizing, voltage " +
                    "regulation, and more. Understanding these relationships is essential for designing and " +
                    "troubleshooting electrical and electronic circuits."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Text {
                text: "<b>Note:</b> Ohm's Law applies to resistive elements in DC circuits and to the magnitude " +
                    "of voltage, current, and impedance in sinusoidal AC circuits."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 10
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: Style.spacing
        

        RowLayout {
            

            WaveCard {
                id: results
                title: "Input Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 210
                Layout.minimumWidth: 350
                Layout.maximumWidth: 350
                Layout.alignment: Qt.AlignTop

                showSettings: true
                
                GridLayout {
                    anchors.margins: Style.spacing
                    columns: 3
                    columnSpacing: Style.spacing
                    rowSpacing: Style.spacing
                    Layout.fillWidth: true
                    
                    Label { text: "Select Two Known Parameters:"; Layout.columnSpan: 3 }
                    
                    Label { text: "Parameter 1:" }
                    ComboBox {
                        id: selectedParam1
                        Layout.minimumWidth: 120
                        Layout.fillWidth: true
                        model: ["Voltage (V)", "Current (I)", "Resistance (R)", "Power (P)"]
                        currentIndex: 0
                        onActivated: {
                            updateParamUnit(0);
                        }
                    }
                    TextField {
                        id: param1Value
                        Layout.minimumWidth: 100
                        placeholderText: "Enter value"
                        text: "12"
                        validator: DoubleValidator {
                            bottom: 0.00001
                            notation: DoubleValidator.StandardNotation
                        }
                        onEditingFinished: calculateOhmsLaw()
                    }
                    
                    Label { text: "Parameter 2:" }
                    ComboBox {
                        id: selectedParam2
                        Layout.fillWidth: true
                        model: ["Voltage (V)", "Current (I)", "Resistance (R)", "Power (P)"]
                        currentIndex: 2
                        onActivated: {
                            updateParamUnit(1);
                        }
                    }
                    TextField {
                        id: param2Value
                        Layout.minimumWidth: 100
                        placeholderText: "Enter value"
                        text: "100"
                        validator: DoubleValidator {
                            bottom: 0.00001
                            notation: DoubleValidator.StandardNotation
                        }
                        onEditingFinished: calculateOhmsLaw()
                    }
                    
                    Button {
                        text: "Calculate " + '\ue5ca'
                        Layout.columnSpan: 3
                        Layout.alignment: Qt.AlignRight
                        onClicked: calculateOhmsLaw()
                        
                    }
                }
            }

            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 210
                Layout.minimumWidth: 250
                Layout.maximumWidth: 250
                Layout.alignment: Qt.AlignTop

                GridLayout {
                    id: resultGrid
                    columns: 2
                    anchors.fill: parent
                    anchors.margins: Style.spacing
                    
                    Label { text: "Voltage (V):" ; Layout.minimumWidth: 100}
                    TextField { 
                        text: calculatorReady ? calculator.voltage.toFixed(1) + " V" : "N/A"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Current (I):" ;}
                    TextField { 
                        text: calculatorReady ? calculator.current.toFixed(1) + " A" : "N/A"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Resistance (R):" ;}
                    TextField {
                        text: calculatorReady ? calculator.resistance.toFixed(1) + " Ω" : "N/A"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Power (P):" ;}
                    TextField { 
                        text: calculatorReady ? calculator.power.toFixed(1) + " W" : "N/A"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                    }
                }
            }
        }

        WaveCard {
            title: "Ohm's Law Formulas"
            Layout.fillWidth: true
            Layout.minimumHeight: 400
            Layout.alignment: Qt.AlignTop
            
            OhmsLawViz {
                id: ohmsLawCanvas
            }
            
        }
    }

    function updateParamUnit(paramIndex) {
        if (selectedParam1.currentIndex === selectedParam2.currentIndex) {
            if (paramIndex === 0) {
                selectedParam2.currentIndex = (selectedParam1.currentIndex + 2) % 4;
            } else {
                selectedParam1.currentIndex = (selectedParam2.currentIndex + 2) % 4;
            }
        }
    }
    
    Component.onCompleted: {
        calculateOhmsLaw()
    }

    Connections {
        target: calculator
        function onCalculationCompleted() {
            updateVisualization()
        }
    }
}
