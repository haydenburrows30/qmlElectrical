import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import Conversion 1.0

Rectangle {
    color: Universal.background // Use theme background color
    
    ConversionCalculator {
        id: converter
    }
    
    property string activeComboBox: "conversionType"

    RowLayout {
        anchors.centerIn: parent
        anchors.margins: 20
        spacing: 20

        ColumnLayout {
            spacing: 20

            ComboBox {
                id: conversionType
                Layout.minimumWidth: 200
                model: [
                    "Line to Phase Voltage",
                    "Phase to Line Voltage",
                    "Line to Phase Current",
                    "Phase to Line Current",
                ]
                onCurrentTextChanged: {
                    converter.setConversionType(currentText.toLowerCase().replace(/ /g, "_"))
                    activeComboBox = "conversionType"
                }
                onActivated: {
                    activeComboBox = "conversionType"
                }
            }

            ComboBox {
                id: wHRPM
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
                ]
                onCurrentTextChanged: {
                    converter.setConversionType(currentText.toLowerCase().replace(/ /g, "_"))
                    activeComboBox = "wHRPM"
                }
                onActivated: {
                    activeComboBox = "wHRPM"
                }
            }

            ComboBox {
                id: temp
                Layout.minimumWidth: 200
                model: [
                    "Celsius to Fahrenheit",
                    "Fahrenheit to Celsius"
                ]
                onCurrentTextChanged: {
                    converter.setConversionType(currentText.toLowerCase().replace(/ /g, "_"))
                    activeComboBox = "temp"
                }
                onActivated: {
                    activeComboBox = "temp"
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

        Rectangle {
            Layout.minimumHeight: 200
            Layout.minimumWidth: 400
            radius: 5
            border.color: "#cccccc"

            Image {
                id: formulaImage
                anchors.centerIn: parent
                width: parent.width * 2
                height: width
                fillMode: Image.PreserveAspectFit
                source: {
                    let formulaPath = "../../../assets/formulas/"
                    
                    // Use activeComboBox to determine which dropdown to check
                    if (activeComboBox === "conversionType") {
                        switch(conversionType.currentText.toLowerCase().replace(/ /g, "_")) {
                            case "line_to_phase_voltage": return formulaPath + "line_phase_voltage.png"
                            case "phase_to_line_voltage": return formulaPath + "phase_line_voltage.png"
                            case "line_to_phase_current": return formulaPath + "line_phase_current.png"
                            case "phase_to_line_current": return formulaPath + "phase_line_current.png"
                            case "kva_to_kw_pf": return formulaPath + "kva_to_kw.png"
                            case "per_unit_voltage": return formulaPath + "per_unit.png"
                            case "impedance_base_change": return formulaPath + "impedance_base_change.png"
                            case "sequence_pos_to_abc": return formulaPath + "sequence_pos.png"
                            case "sequence_neg_to_abc": return formulaPath + "sequence_neg.png"
                            case "sym_to_phase_fault": return formulaPath + "sym_fault.png"
                            case "power_three_to_single": return formulaPath + "three_phase_power.png"
                            case "reactance_freq_change": return formulaPath + "reactance_freq.png"
                        }
                    } else if (activeComboBox === "wHRPM") {
                        switch(wHRPM.currentText.toLowerCase().replace(/ /g, "_")) {
                            case "watts_to_dbmw": return formulaPath + "watts_to_dbm.png"
                            case "dbmw_to_watts": return formulaPath + "dbmw_to_watts.png"
                            case "rad/s_to_hz": return formulaPath + "rad_to_hz.png"
                            case "radians_to_hz": return formulaPath + "radians_to_hz.png"
                            case "horsepower_to_watts": return formulaPath + "hp_to_watts.png"
                            case "rpm_to_hz": return formulaPath + "rpm_to_hz.png"
                            case "hz_to_rpm": return formulaPath + "hz_to_rpm.png"
                            case "watts_to_horsepower": return formulaPath + "watts_to_horsepower.png"
                        }
                    } else if (activeComboBox === "temp") {
                        switch(temp.currentText.toLowerCase().replace(/ /g, "_")) {
                            case "celsius_to_fahrenheit": return formulaPath + "celsius_to_fahrenheit.png"
                            case "fahrenheit_to_celsius": return formulaPath + "fahrenheit_to_celsius.png"
                        }
                    }
                    
                    return ""
                }
            }
        }
    }
}
