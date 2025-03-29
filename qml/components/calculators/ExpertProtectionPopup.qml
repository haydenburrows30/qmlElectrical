import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../backgrounds"
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
        spacing: Style.spacing
        
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
                columnSpacing: 20
                rowSpacing: 10

                Label { text: "Detailed System Calculations"; font.bold: true }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Z0 Transformer (Ω):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: {
                        if (!calculator) return "0.000";
                        let z_base = safeValueFunction((calculator.transformerRating * 1000) / (calculator.transformerImpedance / 100), 1);
                        let z0 = 0.85 * z_base;
                        return safeValueFunction(z0, 0).toFixed(3);
                    }
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Z0 Line (Ω):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: {
                        if (!calculator) return "0.000";
                        let z = Math.sqrt(Math.pow(3 * safeValueFunction(calculator.lineR, 0.25) * 
                                         safeValueFunction(calculator.lineLength, 5), 2) + 
                                        Math.pow(3 * safeValueFunction(calculator.lineX, 0.2) * 
                                         safeValueFunction(calculator.lineLength, 5), 2));
                        return safeValueFunction(z, 0).toFixed(3);
                    }
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Zn Referred (Ω):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: {
                        if (!calculator) return "0.000";
                        // Calculate neutral grounding impedance referred to HV side
                        let z_ng = 5.0; // Default neutral grounding resistance
                        let z_ng_referred = z_ng * Math.pow(11000 / 400, 2);
                        return safeValueFunction(z_ng_referred, 0).toFixed(1);
                    }
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Load Angle (degrees):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? (Math.acos(safeValueFunction(calculator.loadPowerFactor, 0.85)) * 180 / Math.PI).toFixed(1) : "0.0"
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Load MVA Value:" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? (safeValueFunction(calculator.loadMVA, 0.001)).toFixed(3): "0.001"
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Load Current (A):" }
                TextField {
                    id: loadCurrentField
                    readOnly: true
                    Layout.fillWidth: true
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
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Ground Fault Current (A):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? safeValueFunction(calculator.groundFaultCurrent, 10).toFixed(2) : "0.00"
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Voltage Drop:" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? 
                        `${safeValueFunction(calculator.voltageDrop, 0.01).toFixed(2)}% ∠${(Math.acos(safeValueFunction(calculator.loadPowerFactor, 0.85)) * 180 / Math.PI).toFixed(1)}°` : 
                        "0.00% ∠0.0°"
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Receiving End Voltage:" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? 
                        `${safeValueFunction(calculator.unregulatedVoltage, 11).toFixed(2)} kV` : 
                        "11.00 kV"
                    background: ProtectionRectangle {}
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
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
                    background: ProtectionRectangle {}
                }

                Label { text: "Under/Over Frequency (Hz):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? 
                        calculator.frequencyRelaySettings.under_freq.toFixed(1) + " / " + 
                        calculator.frequencyRelaySettings.over_freq.toFixed(1) : "47.5 / 51.5"
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Rate of Change (Hz/s):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? calculator.frequencyRelaySettings.df_dt.toFixed(2) : "0.50"
                    background: ProtectionRectangle {}
                }

                Label { text: "Under/Over Voltage (pu):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? 
                        calculator.voltageRelaySettings.under_voltage.toFixed(2) + " / " +
                        calculator.voltageRelaySettings.over_voltage.toFixed(2) : "0.80 / 1.20"
                    background: ProtectionRectangle {}
                }
                
                Label { text: "Differential Slope (%):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? safeValueFunction(calculator.differentialRelaySlope, 25).toString() : "25"
                    background: ProtectionRectangle {}
                }

                Label { text: "Reverse Power Trip (%):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? (calculator.reversePowerThreshold * 100).toFixed(1) : "-10.0"
                    background: ProtectionRectangle {}
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: Style.spacing

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
