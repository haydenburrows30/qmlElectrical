import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: expertPopup
    modal: true
    padding: 20
    width: 600
    height: 500
    
    property var calculator
    property var safeValueFunction
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        Label {
            text: "Expert Protection Settings"
            font.bold: true
            font.pixelSize: 16
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            GridLayout {
                width: parent.width
                columns: 2
                columnSpacing: 20
                rowSpacing: 10
                
                // Add detailed calculations section first
                Label { text: "Detailed System Calculations"; font.bold: true }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Z0 Transformer (Ω):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: {
                        let z_base = (calculator.transformerRating * 1000) / (calculator.transformerImpedance / 100)
                        let z0 = 0.85 * z_base
                        return safeValueFunction(z0, 0).toFixed(3)
                    }
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Z0 Line (Ω):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: {
                        let z = Math.sqrt(Math.pow(3 * calculator.lineR * calculator.lineLength, 2) + 
                                        Math.pow(3 * calculator.lineX * calculator.lineLength, 2))
                        return safeValueFunction(z, 0).toFixed(3)
                    }
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Zn Referred (Ω):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: safeValueFunction(calculator.groundFaultCurrent, 0).toFixed(3)
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Load Angle (degrees):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: (Math.acos(calculator.loadPowerFactor) * 180 / Math.PI).toFixed(1)
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Load Current:" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: {
                        let i = (calculator.loadMVA * 1e6) / (Math.sqrt(3) * 11000)
                        let angle = Math.acos(calculator.loadPowerFactor)
                        return `${i.toFixed(1)}∠${(-angle * 180 / Math.PI).toFixed(1)}° A`
                    }
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Voltage Drop:" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: `${calculator.voltageDrop.toFixed(2)}% ∠${(Math.acos(calculator.loadPowerFactor) * 180 / Math.PI).toFixed(1)}°`
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Receiving End Voltage:" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: `${(calculator.unregulatedVoltage).toFixed(2)} kV`
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                // Separator before protection settings
                Rectangle { 
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    height: 2
                    color: "darkgray"
                }
                
                Label { text: "Ground Fault Parameters" }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Ground Fault Current (A):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? safeValueFunction(calculator.groundFaultCurrent, 0).toFixed(2) : "0.00"
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Frequency Protection" }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Under/Over Frequency (Hz):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? 
                        calculator.frequencyRelaySettings.under_freq.toFixed(1) + " / " + 
                        calculator.frequencyRelaySettings.over_freq.toFixed(1) : "47.5 / 51.5"
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Rate of Change (Hz/s):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? calculator.frequencyRelaySettings.df_dt.toFixed(2) : "0.50"
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Voltage Protection" }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Under/Over Voltage (pu):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? 
                        calculator.voltageRelaySettings.under_voltage.toFixed(2) + " / " +
                        calculator.voltageRelaySettings.over_voltage.toFixed(2) : "0.80 / 1.20"
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Differential Protection" }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Differential Slope (%):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? safeValueFunction(calculator.differentialRelaySlope, 0).toString() : "25"
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
                
                Label { text: "Reverse Power Protection" }
                Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                
                Label { text: "Reverse Power Trip (%):" }
                TextField {
                    readOnly: true
                    Layout.fillWidth: true
                    text: calculator ? (calculator.reversePowerThreshold * 100).toFixed(1) : "-10.0"
                    background: Rectangle {
                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                        border.color: "#0078d7"
                        radius: 2
                    }
                }
            }
        }
        
        Button {
            text: "Close"
            Layout.alignment: Qt.AlignRight
            onClicked: expertPopup.close()
        }
    }
}
