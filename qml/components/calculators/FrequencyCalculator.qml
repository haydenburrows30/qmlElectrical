import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import Freq 1.0

WaveCard {
    id: frequencyCalculator
    title: "Resonant Frequency Calculator"

    property FrequencyCalculator calculator: FrequencyCalculator {}

    RowLayout {
        anchors.centerIn: parent
        spacing: 10

        ColumnLayout {
            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Label { text: "Inductance (H):" }
                TextField {
                    id: inductanceInput
                    placeholderText: "Enter inductance"
                    Layout.minimumWidth: 150
                    onTextChanged: if(text) {
                        calculator.inductance = parseFloat(text)
                    }
                }

                Label { text: "Capacitance (μF):" }
                TextField {
                    id: capacitanceInput
                    placeholderText: "Enter capacitance"
                    Layout.minimumWidth: 150
                    onTextChanged: if(text) {
                        calculator.capacitance = parseFloat(text)
                    }
                }
            }

            GroupBox {
                title: "Results"
                Layout.minimumWidth: 300

                 GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Resonant Frequency: " }
                    Label { text:  (calculator && calculator.resonantFrequency ? 
                               calculator.resonantFrequency.toFixed(2) + " Hz" : 
                               "0.00 Hz")
                    }

                    Label { text: "Angular Frequency: "}
                    Label { text: (calculator && calculator.angularFrequency ? 
                               calculator.angularFrequency.toFixed(2) + " rad/s" : 
                               "0.00 rad/s") 
                    }

                }
            }
        }
    }
}
