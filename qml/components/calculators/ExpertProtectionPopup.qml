import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"

Popup {
    id: expertPopup
    modal: true
    padding: 25
    width: 600
    height: 600
    
    property var calculator
    property var safeValueFunction
    
    onOpened: {
        if (calculator) {
            try {
                calculator.refreshCalculations();
                gridLayout.forceActiveFocus();
            } catch (e) {
                console.error("Error refreshing calculations:", e);
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        
        Label {
            text: "Expert Protection Settings"
            font.bold: true
            font.pixelSize: 16
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            GridLayout {
                id: gridLayout
                width: parent.width
                columns: 2
                
                Label { text: "Detailed System Calculations"; font.bold: true }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Z0 Transformer (Ω):" }
                TextFieldBlue {
                    text: {
                        if (!calculator) return "0.000";
                        let z_base = safeValueFunction((calculator.transformerRating * 1000) / (calculator.transformerImpedance / 100), 1);
                        let z0 = 0.85 * z_base;
                        return safeValueFunction(z0, 0).toFixed(3);
                    }
                }
                
                Label { text: "Z0 Line (Ω):" }
                TextFieldBlue {
                    text: {
                        if (!calculator) return "0.000";
                        let z = Math.sqrt(Math.pow(3 * safeValueFunction(calculator.lineR, 0.25) * 
                                         safeValueFunction(calculator.lineLength, 5), 2) + 
                                        Math.pow(3 * safeValueFunction(calculator.lineX, 0.2) * 
                                         safeValueFunction(calculator.lineLength, 5), 2));
                        return safeValueFunction(z, 0).toFixed(3);
                    }
                }
                
                Label { text: "Zn Referred (Ω):" }
                TextFieldBlue {
                    text: {
                        if (!calculator) return "0.000";
                        // Calculate neutral grounding impedance referred to HV side
                        let z_ng = 5.0; // Default neutral grounding resistance
                        let z_ng_referred = z_ng * Math.pow(11000 / 400, 2);
                        return safeValueFunction(z_ng_referred, 0).toFixed(1);
                    }
                }
                
                Label { text: "Load Angle (degrees):" }
                TextFieldBlue {
                    text: calculator ? (Math.acos(safeValueFunction(calculator.loadPowerFactor, 0.85)) * 180 / Math.PI).toFixed(1) : "0.0"
                }
                
                Label { text: "Load MVA Value:" }
                TextFieldBlue {
                    text: calculator ? (safeValueFunction(calculator.loadMVA, 0.001)).toFixed(3): "0.001"
                }
                
                Label { text: "Load Current (A):" }
                TextFieldBlue {
                    id: loadCurrentField
                    text: {
                        if (!calculator) return "0.0∠0° A";
                        
                        // Get MVA from calculator, ensuring we have a minimum value
                        let loadMVA = Math.max(0.001, safeValueFunction(calculator.loadMVA, 0.001));
                        
                        // Calculate load current in amps at 11kV (line-to-line voltage)
                        let currentMagnitude = (loadMVA * 1000000) / (Math.sqrt(3) * 11000);
                        
                        // Calculate angle using power factor
                        let powerFactor = safeValueFunction(calculator.loadPowerFactor, 0.85);
                        let angle = Math.acos(powerFactor);
                        
                        // Format with angle notation
                        return `${currentMagnitude.toFixed(1)}∠${(-angle * 180 / Math.PI).toFixed(1)}° A`;
                    }
                }
                
                Label { text: "Ground Fault Current (A):" }
                TextFieldBlue {
                    text: calculator ? safeValueFunction(calculator.groundFaultCurrent, 10).toFixed(2) : "0.00"
                }
                
                Label { text: "Voltage Drop:" }
                TextFieldBlue {
                    text: calculator ? 
                        `${safeValueFunction(calculator.voltageDrop, 0.01).toFixed(2)}% ∠${(Math.acos(safeValueFunction(calculator.loadPowerFactor, 0.85)) * 180 / Math.PI).toFixed(1)}°` : 
                        "0.00% ∠0.0°"
                }
                
                Label { text: "Receiving End Voltage:" }
                TextFieldBlue {
                    text: calculator ? 
                        `${safeValueFunction(calculator.unregulatedVoltage, 11).toFixed(2)} kV` : 
                        "11.00 kV"
                }
                
                // Separator before protection settings
                Rectangle { 
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    height: 2
                    color: "darkgray"
                }

                Label { text: "Protection Settings"; font.bold: true ; Layout.columnSpan: 2 }
                
                Label { text: "Relay Pickup Current (A):" }
                TextFieldBlue {
                    text: calculator ? safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
                }

                Label { text: "Under/Over Frequency (Hz):" }
                TextFieldBlue {
                    text: calculator ? 
                        calculator.frequencyRelaySettings.under_freq.toFixed(1) + " / " + 
                        calculator.frequencyRelaySettings.over_freq.toFixed(1) : "47.5 / 51.5"
                }
                
                Label { text: "Rate of Change (Hz/s):" }
                TextFieldBlue {
                    text: calculator ? calculator.frequencyRelaySettings.df_dt.toFixed(2) : "0.50"
                }

                Label { text: "Under/Over Voltage (pu):" }
                TextFieldBlue {
                    text: calculator ? 
                        calculator.voltageRelaySettings.under_voltage.toFixed(2) + " / " +
                        calculator.voltageRelaySettings.over_voltage.toFixed(2) : "0.80 / 1.20"
                }
                
                Label { text: "Differential Slope (%):" }
                TextFieldBlue {
                    text: calculator ? safeValueFunction(calculator.differentialRelaySlope, 25).toString() : "25"
                }

                Label { text: "Reverse Power Trip (%):" }
                TextFieldBlue {
                    text: calculator ? (calculator.reversePowerThreshold * 100).toFixed(1) : "-10.0"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            
            Button {
                text: "Refresh Values"
                Layout.alignment: Qt.AlignRight
                onClicked: calculator.refreshCalculations();
            }
            
            Button {
                text: "Close"
                Layout.alignment: Qt.AlignRight
                onClicked: expertPopup.close()
            }
        }
    }
}
