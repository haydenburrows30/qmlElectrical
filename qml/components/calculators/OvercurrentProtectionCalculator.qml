import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../style"
import "../popups"

// Change to the correct import namespace registered in qml_types.py
import OvercurrentProtectionCalculator 1.0

Item {
    id: overcurrentCalculator

    property var calculator: OvercurrentProtectionCalculator {}

    // Fixed updateAllDisplays function - using a valid approach to trigger UI refresh
    function updateAllDisplays() {
        // We can't call emit directly on the signal
        // Instead, set a property that will trigger the dataChanged signal in the model
        calculator.usePercentage = calculator.usePercentage;
    }

    PopUpText {
        parentCard: cableParamsCard
        popupText: "<h3>Overcurrent Protection Calculator</h3><br>" +
                   "This calculator determines recommended settings for:<br>" +
                   "- Phase overcurrent protection (ANSI 50/51)<br>" +
                   "- Earth fault protection (ANSI 50N/51N)<br>" +
                   "- Negative sequence protection (ANSI 50Q)<br><br>" +
                   "Default values are for a 25mm² 11kV XLPE cable with 8km length.<br><br>" +
                   "Results include fault currents and recommended protection settings in both primary amperes and CT secondary values."
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: mainLayout.width + 20
            contentHeight: mainLayout.height + 20
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            ColumnLayout {
                id: mainLayout
                width: mainRowLayout.width
                
                // Main Layout with Cards
                RowLayout {
                    id: mainRowLayout
                    Layout.fillWidth: true
                    
                    // Left Column - Inputs
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        
                        // Cable Parameters Card
                        WaveCard {
                            id: cableParamsCard
                            title: "Cable Parameters"
                            Layout.minimumWidth: 450
                            Layout.minimumHeight: 400
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                
                                // Cable parameters
                                Label { text: "Cross Section (mm²):" ; Layout.minimumWidth: 100}
                                SpinBoxRound {
                                    from: 10
                                    to: 500
                                    value: calculator.cableCrossSection
                                    onValueChanged: calculator.cableCrossSection = value
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 200
                                }
                                
                                Label { text: "Length (km):" }
                                SpinBoxRound {
                                    from: 1
                                    to: 500
                                    stepSize: 1
                                    value: Math.round(calculator.cableLength * 10)
                                    onValueChanged: {
                                        calculator.cableLength = value / 10;
                                    }
                                    textFromValue: function(value) {
                                        return (value / 10).toFixed(1);
                                    }
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }
                                    Layout.fillWidth: true
                                    editable: true
                                }
                                
                                Label { text: "Voltage (V):" }
                                SpinBoxRound {
                                    from: 1000
                                    to: 36000
                                    stepSize: 1000
                                    value: calculator.cableVoltage
                                    onValueChanged: calculator.cableVoltage = value
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Cable Material:" }
                                ComboBoxRound {
                                    model: ["Copper", "Aluminum"]
                                    currentIndex: model.indexOf(calculator.cableMaterial)
                                    onCurrentTextChanged: calculator.cableMaterial = currentText
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Cable Type:" }
                                ComboBoxRound {
                                    model: ["XLPE", "PVC", "EPR"]
                                    currentIndex: model.indexOf(calculator.cableType)
                                    onCurrentTextChanged: calculator.cableType = currentText
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Installation:" }
                                ComboBoxRound {
                                    model: ["Direct Buried", "Duct", "Tray", "Aerial"]
                                    currentIndex: model.indexOf(calculator.cableInstallation)
                                    onCurrentTextChanged: calculator.cableInstallation = currentText
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Ambient Temp (°C):" }
                                SpinBoxRound {
                                    from: -10
                                    to: 60
                                    value: calculator.ambientTemperature
                                    onValueChanged: calculator.ambientTemperature = value
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Soil Resistivity (Ω·m):" }
                                SpinBoxRound {
                                    from: 10
                                    to: 1000
                                    value: calculator.soilResistivity
                                    onValueChanged: calculator.soilResistivity = value
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        
                        // System Parameters Card
                        WaveCard {
                            title: "System Parameters"
                            Layout.minimumWidth: 450
                            Layout.minimumHeight: 260
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                
                                Label { text: "System Fault Level (MVA):" ; Layout.minimumWidth: 100}
                                SpinBoxRound {
                                    from: 50
                                    to: 1000
                                    value: calculator.systemFaultLevel
                                    onValueChanged: calculator.systemFaultLevel = value
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 200
                                }
                                
                                Label { text: "Transformer Rating (MVA):" }
                                SpinBoxRound {
                                    from: 3  // 0.3 MVA (300kVA)
                                    to: 1000 // 100 MVA
                                    stepSize: 1
                                    value: Math.round(calculator.transformerRating * 10)
                                    onValueChanged: calculator.transformerRating = value / 10
                                    textFromValue: function(value) {
                                        return (value / 10).toFixed(1);
                                    }
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }
                                    Layout.fillWidth: true
                                    editable: true
                                }
                                
                                Label { text: "CT Ratio:" }
                                SpinBoxRound {
                                    from: 50
                                    to: 2000
                                    stepSize: 50
                                    value: calculator.ctRatio
                                    onValueChanged: {
                                        calculator.ctRatio = value;
                                        // Force update of display text for percentage values
                                        if (calculator.usePercentage) {
                                            phase50PickupLabel.text = calculator.convertToPercentage(calculator.iPickup50).toFixed(1) + " %";
                                            phase51PickupLabel.text = calculator.convertToPercentage(calculator.iPickup51).toFixed(1) + " %";
                                            earth50nPickupLabel.text = calculator.convertToPercentage(calculator.iPickup50N).toFixed(1) + " %";
                                            earth51nPickupLabel.text = calculator.convertToPercentage(calculator.iPickup51N).toFixed(1) + " %";
                                            neg50qPickupLabel.text = calculator.convertToPercentage(calculator.iPickup50Q).toFixed(1) + " %";
                                        }
                                    }
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Display Values:" }
                                RowLayout {
                                    RadioButton {
                                        id: amperesRadioButton
                                        text: "Amperes"
                                        checked: !calculator.usePercentage
                                        onClicked: {
                                            calculator.usePercentage = false;
                                            updateAllDisplays();
                                        }
                                    }
                                    RadioButton {
                                        id: ctPercentageRadioButton
                                        text: "CT %"
                                        checked: calculator.usePercentage
                                        onClicked: {
                                            calculator.usePercentage = true;
                                            updateAllDisplays();
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Right Column - Results
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        
                        // Cable & Fault Results
                        WaveCard {
                            title: "Cable & Fault Analysis"
                            Layout.minimumWidth: 400
                            Layout.minimumHeight: 230
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                
                                // Cable results
                                Label { 
                                    text: "Cable Impedance:" 
                                    font.bold: true
                                    Layout.minimumWidth: 100
                                }
                                Label { 
                                    text: calculator.cableImpedance.toFixed(3) + " Ω"
                                    Layout.minimumWidth: 200
                                }
                                
                                Label { 
                                    text: "Max Load Current:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.maxLoadCurrent.toFixed(1) + " A" 
                                }
                                
                                // Fault results
                                Label { 
                                    text: "3-Phase Fault Current:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.faultCurrent3Ph.toFixed(1) + " A" 
                                }
                                
                                Label { 
                                    text: "Phase-Phase Fault Current:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.faultCurrent2Ph.toFixed(1) + " A" 
                                }
                                
                                Label { 
                                    text: "Phase-Earth Fault Current:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.faultCurrent1Ph.toFixed(1) + " A" 
                                }
                            }
                        }
                        
                        // Phase Overcurrent Protection
                        WaveCard {
                            title: "Phase Overcurrent Protection"
                            Layout.minimumWidth: 400
                            Layout.minimumHeight: 250
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                
                                // 50 - Instantaneous OC
                                Label { 
                                    text: "50 Pickup:" 
                                    font.bold: true
                                }
                                Label { 
                                    id: phase50PickupLabel
                                    text: calculator.usePercentage ? 
                                          calculator.convertToPercentage(calculator.iPickup50).toFixed(1) + " %" : 
                                          calculator.iPickup50.toFixed(1) + " A"
                                    Layout.minimumWidth: 200
                                }
                                
                                Label { 
                                    text: "50 Time Delay:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.timeDelay50.toFixed(2) + " s" 
                                }
                                
                                // 51 - Time OC
                                Label { 
                                    text: "51 Pickup:" 
                                    font.bold: true
                                }
                                Label { 
                                    id: phase51PickupLabel
                                    text: calculator.usePercentage ? 
                                        calculator.convertToPercentage(calculator.iPickup51).toFixed(1) + " %" : 
                                        calculator.iPickup51.toFixed(1) + " A"
                                }
                                
                                Label { 
                                    text: "51 Time Dial:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.timeDial51.toFixed(2) 
                                }
                                
                                Label { 
                                    text: "51 Curve Type:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.curveType51
                                }
                            }
                        }

                        // Earth Fault Protection
                        WaveCard {
                            title: "Earth Fault Protection"
                            Layout.minimumWidth: 400
                            Layout.minimumHeight: 300
                            Layout.alignment: Qt.AlignTop
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                
                                // 50N - Instantaneous EF
                                Label { 
                                    text: "50N Pickup:" 
                                    font.bold: true
                                    Layout.minimumWidth: 100
                                }
                                Label {  // Changed from SpinBoxRound to Label
                                    id: earth50nPickupLabel
                                    text: calculator.usePercentage ? 
                                        calculator.convertToPercentage(calculator.iPickup50N).toFixed(1) + " %" : 
                                        calculator.iPickup50N.toFixed(1) + " A"
                                    Layout.minimumWidth: 200
                                }
                                
                                Label { 
                                    text: "50N Time Delay:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.timeDelay50N.toFixed(2) + " s" 
                                }
                                
                                // 51N - Time EF
                                Label { 
                                    text: "51N Pickup:" 
                                    font.bold: true
                                }
                                Label { 
                                    id: earth51nPickupLabel
                                    text: calculator.usePercentage ? 
                                        calculator.convertToPercentage(calculator.iPickup51N).toFixed(1) + " %" : 
                                        calculator.iPickup51N.toFixed(1) + " A"
                                }
                                
                                Label { 
                                    text: "51N Time Dial:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.timeDial51N.toFixed(2) 
                                }
                                
                                Label { 
                                    text: "51N Curve Type:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.curveType51N
                                }
                                
                                // 50Q - Negative Sequence
                                Label { 
                                    text: "50Q Pickup:" 
                                    font.bold: true
                                }
                                Label {
                                    id: spinPickup50Q
                                    text: calculator.usePercentage ? 
                                        calculator.convertToPercentage(calculator.iPickup50Q).toFixed(1) + " %" : 
                                        calculator.iPickup50Q.toFixed(1) + " A"
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "50Q Time Delay:" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.timeDelay50Q.toFixed(2) + " s" 
                                }
                            }
                        }
                    }

                    // Notes section
                    WaveCard {
                        title: "Protection Notes"
                        Layout.minimumWidth: 400
                        Layout.minimumHeight: 300
                        Layout.alignment: Qt.AlignTop
                        
                        ColumnLayout {
                            anchors.fill: parent
                            
                            Label {
                                text: "Protection Guidelines"
                                font.bold: true
                                font.pixelSize: 16
                                Layout.minimumWidth: 100
                            }
                            
                            Label {
                                text: "• Phase Instantaneous (50): Set above maximum load and below minimum fault current" 
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 200
                            }
                            
                            Label {
                                text: "• Phase Time-Delayed (51): Set above maximum load with sufficient margin" 
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: "• Earth Fault (50N/51N): Set below minimum earth fault current but above system charging current" 
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: "• Negative Sequence (50Q): Provides increased sensitivity for unbalanced faults" 
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}