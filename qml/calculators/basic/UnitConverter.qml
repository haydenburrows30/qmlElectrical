import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../"
import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

import Conversion 1.0

Item {
    
    ConversionCalculator {
        id: converter
    }

    function rfocusChanged() {
        const textElements = {
            'conversionType': conversionTypeText,
            'wHRPM': wHRPMText,
            'temp': tempText
        }
        
        // // Reset all to default
        Object.values(textElements).forEach(element => {
                element.font.bold = false
        })
        
        // Highlight active one
        // textElements[activeComboBox].color = "blue"
        textElements[activeComboBox].font.bold = true
    }
    
    property string activeComboBox: "conversionType"

    RowLayout {
        anchors.centerIn: parent

        WaveCard {
            id: results
            Layout.minimumHeight: 400
            Layout.minimumWidth: 600
            title: "Unit Converter"

            ColumnLayout {
                id: waveCardLayout
                anchors.centerIn: parent

                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 140

                    ColumnLayout {
                        id: conversionTypeLayout
                        
                        RowLayout {
                            Label {
                                text: "Voltage"
                                Layout.minimumWidth: 100
                                font.bold: true
                                font.pixelSize: 16
                            }

                            ComboBoxRound {
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
                                    rfocusChanged()
                                }

                                contentItem: Label {
                                    id: conversionTypeText
                                    leftPadding: 10
                                    text: conversionType.displayText
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        RowLayout {
                            Label {
                                text: "Frequency"
                                font.bold: true
                                font.pixelSize: 16
                                Layout.minimumWidth: 100
                            }

                            ComboBoxRound {
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
                                    rfocusChanged()
                                }

                                contentItem: Label {
                                    id: wHRPMText
                                    leftPadding: 10
                                    text: wHRPM.displayText
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        RowLayout {
                            Label {
                                text: "Temperature"
                                font.bold: true
                                font.pixelSize: 16
                                Layout.minimumWidth: 100
                            }

                            ComboBoxRound {
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
                                    rfocusChanged()
                                }

                                contentItem: Label {
                                    id: tempText
                                    leftPadding: 10
                                    text: temp.displayText
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillHeight: true
                        TextArea {
                            id: enterField
                            placeholderText: "Enter value"
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.minimumHeight: conversionTypeLayout.height
                            font.pixelSize: 34

                            onTextChanged: {
                                if (text) converter.setInputValue(parseFloat(text))
                            }
                            wrapMode: TextEdit.Wrap
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumHeight: 80

                    Label {
                        text: converter.result.toFixed(2)
                        font.pixelSize: 34
                        color: Style.textFieldBorder
                    }

                    Label {
                        text: {
                            if (activeComboBox === "conversionType") {
                                switch(conversionType.currentText.toLowerCase().replace(/ /g, "_")) {
                                    case "line_to_phase_voltage":
                                    case "phase_to_line_voltage": return "V"
                                    case "line_to_phase_current":
                                    case "phase_to_line_current": return "A"
                                    default: return ""
                                }
                            } else if (activeComboBox === "wHRPM") {
                                switch(wHRPM.currentText.toLowerCase().replace(/ /g, "_")) {
                                    case "watts_to_dbmw": return "dBmW"
                                    case "dbmw_to_watts": return "W"
                                    case "rad/s_to_hz":
                                    case "radians_to_hz":
                                    case "rpm_to_hz": return "Hz"
                                    case "horsepower_to_watts": return "W"
                                    case "hz_to_rpm": return "RPM"
                                    case "watts_to_horsepower": return "HP"
                                    default: return ""
                                }
                            } else if (activeComboBox === "temp") {
                                switch(temp.currentText.toLowerCase().replace(/ /g, "_")) {
                                    case "celsius_to_fahrenheit": return "°F"
                                    case "fahrenheit_to_celsius": return "°C"
                                    default: return ""
                                }
                            }
                            return ""
                        }
                        font.pixelSize: 34
                        color: Style.textFieldBorder
                    }
                }

                Rectangle {
                    id: formulaContainer
                    Layout.maximumWidth: 800
                    Layout.minimumHeight: 100
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Image {
                        id: formulaImage
                        anchors.centerIn: formulaContainer
                        fillMode: Image.PreserveAspectFit
                        source: {
                            let formulaPath = "../../../assets/formulas/"

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
    }
}
