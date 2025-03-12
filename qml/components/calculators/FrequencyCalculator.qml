import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import Freq 1.0

WaveCard {
    id: frequencyCalculator
    title: "Resonant Frequency Calculator"
    Layout.minimumWidth: 600
    Layout.minimumHeight: 200

    // Create instance of calculator
    property FrequencyCalculator calculator: FrequencyCalculator {}

    RowLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 300

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Label { text: "Inductance (H):" }
                TextField {
                    id: inductanceInput
                    placeholderText: "Enter inductance"
                    onTextChanged: if(text) {
                        calculator.inductance = parseFloat(text)
                    }
                }

                Label { text: "Capacitance (μF):" }
                TextField {
                    id: capacitanceInput
                    placeholderText: "Enter capacitance"
                    onTextChanged: if(text) {
                        calculator.capacitance = parseFloat(text)
                    }
                }
            }

            GroupBox {
                title: "Results"
                Layout.fillWidth: true
                
                ColumnLayout {
                    Label { 
                        text: "Resonant Frequency: " + 
                              (calculator && calculator.resonantFrequency ? 
                               calculator.resonantFrequency.toFixed(2) + " Hz" : 
                               "0.00 Hz")
                    }
                    Label { 
                        text: "Angular Frequency: " + 
                              (calculator && calculator.angularFrequency ? 
                               calculator.angularFrequency.toFixed(2) + " rad/s" : 
                               "0.00 rad/s") 
                    }
                }
            }
        }
    }
}
