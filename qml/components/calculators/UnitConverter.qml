import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Conversion 1.0

Rectangle {
    ConversionCalculator {
        id: converter
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Left side - converter controls
        ColumnLayout {
            // Layout.preferredWidth: parent.width * 0.5
            spacing: 20

            ComboBox {
                id: conversionType
                Layout.minimumWidth: 200
                model: [
                    "Watts to dBmW",
                    "dBmW to Watts",
                    "Rad/s to Hz",
                    "Horsepower to Watts",
                    "RPM to Hz",
                    "Radians to Hz",
                    "Hz to RPM",
                    "Watts to Horsepower",
                    "kW to MVA",
                    "MVA to kW",
                    "Joules to kWh",
                    "kWh to Joules",
                    "Celsius to Fahrenheit",
                    "Fahrenheit to Celsius",
                    "kV to V",
                    "V to kV",
                    "mH to H",
                    "H to mH",
                    "μF to F",
                    "F to μF",
                    "kVAr to VAr",
                    "VAr to kVAr",
                    "MVAr to VAr",
                    "VAr to MVAr",
                    "mA to A",
                    "A to mA",
                    "kA to A", 
                    "A to kA",
                    "Ohm to kOhm",
                    "kOhm to Ohm",
                    "MOhm to Ohm",
                    "Ohm to MOhm",
                    "kVA to kW (PF=0.8)",
                    "kW to kVA (PF=0.8)",
                    "Line to Phase Voltage",
                    "Phase to Line Voltage",
                    "Line to Phase Current",
                    "Phase to Line Current",
                    "kWh to MWh",
                    "MWh to kWh",
                    "VA to W (PF=0.8)",
                    "W to VA (PF=0.8)",
                    "Impedance Base Change (100MVA)",
                    "Sequence + to ABC (A phase)",
                    "Sequence - to ABC (A phase)",
                    "Voltage to Per Unit (11kV base)",
                    "Actual to Per Unit Z",
                    "Symmetrical to Phase Fault",
                    "3-Phase to Single-Phase Power",
                    "Reactance 50Hz to 60Hz"
                ]
                onCurrentTextChanged: {
                    converter.setConversionType(currentText.toLowerCase().replace(/ /g, "_"))
                }
            }

            TextField {
                Layout.minimumWidth: 200
                placeholderText: "Enter value"
                onTextChanged: {
                    if (text) converter.setInputValue(parseFloat(text))
                }
                validator: DoubleValidator {}
            }

            Label {
                text: "Result: " + converter.result.toFixed(3)
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Right side - formula display
        Rectangle {
            Layout.minimumHeight: 500
            Layout.minimumWidth: 500
            color: "#f5f5f5"
            radius: 5
            border.color: "#cccccc"

            Image {
                id: formulaImage
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: width * 0.6
                fillMode: Image.PreserveAspectFit
                source: {
                    let formulaPath = "/home/hayden/Documents/qmltest/assets/formulas/"
                    switch(conversionType.currentText.toLowerCase().replace(/ /g, "_")) {
                        case "watts_to_dbmw": return formulaPath + "watts_to_dbm.png"
                        case "horsepower_to_watts": return formulaPath + "hp_to_watts.png"
                        case "rad_to_hz": return formulaPath + "rad_to_hz.png"
                        case "rpm_to_hz": return formulaPath + "rpm_to_hz.png"
                        case "line_to_phase_voltage": return formulaPath + "line_phase_voltage.png"
                        case "phase_to_line_voltage": return formulaPath + "phase_line_voltage.png"
                        case "line_to_phase_current": return formulaPath + "line_phase_current.png"
                        case "kva_to_kw_pf": return formulaPath + "kva_to_kw.png"
                        case "per_unit_voltage": return formulaPath + "per_unit.png"
                        case "impedance_base_change": return formulaPath + "impedance_base_change.png"
                        case "sequence_pos_to_abc": return formulaPath + "sequence_pos.png"
                        case "sequence_neg_to_abc": return formulaPath + "sequence_neg.png"
                        case "sym_to_phase_fault": return formulaPath + "sym_fault.png"
                        case "power_three_to_single": return formulaPath + "three_phase_power.png"
                        case "reactance_freq_change": return formulaPath + "reactance_freq.png"
                        default: return ""
                    }
                }
            }
        }
    }
}
