import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"

WaveCard {
    id: conversionCalculator
    title: 'Conversion Calculator'
    Layout.minimumWidth: 300
    Layout.minimumHeight: 200

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
                    conversionCalc.setInputValue(parseFloat(text))
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
                onCurrentTextChanged: conversionCalc.setConversionType(currentText)
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
                text: conversionCalc.result.toFixed(2)
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
