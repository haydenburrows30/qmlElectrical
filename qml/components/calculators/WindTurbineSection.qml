import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"  // Import for WaveCard component

Item {
    id: windTurbineSection
    
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
            contentHeight: mainLayout.height + 10
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                width: scrollView.width

                RowLayout {

                    WaveCard {
                        title: "Wind Turbine Parameters"
                        // Layout.fillWidth: true
                        Layout.preferredHeight: 270
                        Layout.minimumWidth: 350
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10
                            
                            Label { text: "Blade Radius (m):" }
                            SpinBox {
                                id: bladeRadiusSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.bladeRadius : 40
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setBladeRadius(value)
                                    }
                                }
                            }
                            
                            Label { text: "Wind Speed (m/s):" }
                            SpinBox {
                                id: windSpeedSpinBox
                                from: 1
                                to: 30
                                value: calculatorReady ? calculator.windSpeed : 8
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setWindSpeed(value)
                                    }
                                }
                            }
                            
                            Label { text: "Power Coefficient (Cp):" }
                            SpinBox {
                                id: powerCoefficientSpinBox
                                from: 0
                                to: 60
                                value: calculatorReady ? calculator.powerCoefficient * 100 : 40
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100
                                
                                textFromValue: function(value) {
                                    return (value / 100).toFixed(2);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setPowerCoefficient(realValue)
                                    }
                                }
                            }
                            
                            Label { text: "Generator Efficiency (%):" }
                            SpinBox {
                                id: efficiencySpinBox
                                from: 50
                                to: 100
                                value: calculatorReady ? calculator.efficiency * 100 : 90
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setEfficiency(value / 100)
                                    }
                                }
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Wind Turbine Output"
                        // Layout.fillWidth: true
                        Layout.preferredHeight: 270
                        Layout.minimumWidth: 500
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10
                            
                            Label { text: "Power Output (kW):" }
                            TextField {
                                id: powerKWText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.powerInKW, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Generator Rated Capacity (kVA):" }
                            TextField {
                                id: genCapacityText
                                readOnly: true
                                Layout.fillWidth: true
                                text: (totalGeneratedPower * 1.2).toFixed(2)
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Generator Output Current (A):" }
                            TextField {
                                id: genCurrentText
                                readOnly: true
                                Layout.fillWidth: true
                                // I = S/(√3 × V) for three-phase systems
                                text: totalGeneratedPower > 0 
                                    ? ((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)).toFixed(2)
                                    : "0.00"
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Annual Energy Production (MWh/year):" }
                            TextField {
                                id: annualEnergyText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.annualEnergy, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Button {
                                text: "Calculate Wind Output"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: calculate()
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Wind Turbine Generator Protection Requirements"
                        // Layout.fillWidth: true
                        Layout.preferredHeight: 270
                        Layout.minimumWidth: 400
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            Text {
                                text: "<b>400V Generator Protection Requirements:</b><br>" +
                                    "• Over/Under Voltage Protection (27/59)<br>" +
                                    "• Over/Under Frequency Protection (81O/81U)<br>" +
                                    "• Overcurrent Protection (50/51)<br>" +
                                    "• Earth Fault Protection (50N/51N)<br>" +
                                    "• Reverse Power Protection (32)<br>" +
                                    "• Loss of Excitation Protection (40)<br>" +
                                    "• Stator Earth Fault Protection<br>" +
                                    "• Anti-Islanding Protection"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
    
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
            powerKWText.text = safeValueFunction(calculator.powerInKW, 0).toFixed(2)
            genCapacityText.text = (calculator.powerInKW * 1.2).toFixed(2)
            
            // Calculate generator current at 400V
            var genCurrent = (calculator.powerInKW * 1000) / (Math.sqrt(3) * 400)
            genCurrentText.text = safeValueFunction(genCurrent, 0).toFixed(2)
            
            annualEnergyText.text = safeValueFunction(calculator.annualEnergy, 0).toFixed(2)
        }
    }
}
