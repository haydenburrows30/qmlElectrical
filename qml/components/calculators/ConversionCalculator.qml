import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import ConvCalc 1.0

WaveCard {
    id: conversionCard
    title: 'Unit Conversion'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 200

    property ConversionCalculator calculator: ConversionCalculator {}

    ColumnLayout {

        RowLayout {
            spacing: 10

            Label {
                text: "Input Value:"
                Layout.preferredWidth: 110
            }

            TextField {
                id: inputValue
                placeholderText: "Enter Value"
                onTextChanged: {
                    if (text) calculator.value = parseFloat(text)
                }
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
        }

        RowLayout {
            spacing: 10

            Label {
                text: "Conversion Type:"
                Layout.preferredWidth: 110
            }

            ComboBox {
                id: conversionType
                model: ["watts_to_dbmw", "dbmw_to_watts", "rad_to_hz", "hp_to_watts", "rpm_to_hz", "radians_to_hz", "hz_to_rpm", "watts_to_hp"]
                onCurrentTextChanged: calculator.setFromUnit(currentText)
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }

            ComboBox {
                id: conversionTypeTo
                model: ["watts_to_dbmw", "dbmw_to_watts", "rad_to_hz", "hp_to_watts", "rpm_to_hz", "radians_to_hz", "hz_to_rpm", "watts_to_hp"]
                onCurrentTextChanged: calculator.setToUnit(currentText)
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
        }

        RowLayout {
            spacing: 10
            Layout.topMargin: 5

            Label {
                text: "Result:"
                Layout.preferredWidth: 110
            }

            Text {
                id: conversionResult
                text: calculator && !isNaN(calculator.result) ? 
                      calculator.result.toFixed(3) + " " + calculator.toUnit : "0.000"
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
