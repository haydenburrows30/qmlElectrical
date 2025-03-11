import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import Fault 1.0  // Import the correct namespace for the fault current calculator

WaveCard {
    id: fault_current
    title: 'Impedance'

    // Create a local instance of our calculator
    property FaultCurrentCalculator calculator: FaultCurrentCalculator {}

    RowLayout {
        anchors.centerIn: parent
        
        ColumnLayout {

            RowLayout {
                spacing: 5
                Label {
                    text: "Resistance(R):"
                    Layout.preferredWidth: 100
                }
                TextField {
                    id: rInput
                    placeholderText: "Enter Resistance"
                    onTextChanged: {
                        if (text && calculator) {
                            calculator.setResistance(parseFloat(text))
                        }
                    }
                    Layout.preferredWidth: 130
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 5
                Label {
                    text: "Reactance (X):"
                    Layout.preferredWidth: 100
                }
                TextField {
                    id: reactanceInput
                    Layout.preferredWidth: 130
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Reactance"
                    onTextChanged: {
                        if (text && calculator) {
                            calculator.setReactance(parseFloat(text))
                        }
                    }
                }
            }

            RowLayout {
                spacing: 5
                Layout.topMargin: 5
                Label {
                    text: "Impedance (Z):"
                    Layout.preferredWidth: 110
                }
                Text {
                    id: impedanceOutput
                    text: calculator && !isNaN(calculator.impedance) ? 
                          calculator.impedance.toFixed(2) + "Ω" : "0.00Ω"
                    Layout.preferredWidth: 130
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        ImpedanceVectorViz {
            id: impedanceViz
            Layout.minimumWidth: 300
            Layout.minimumHeight: 300
            resistance: parseFloat(rInput.text || "3")
            reactance: parseFloat(reactanceInput.text || "4")
            impedance: calculator && !isNaN(calculator.impedance) ? 
                       parseFloat(calculator.impedance.toFixed(2)) : 5.0
            phaseAngle: calculator && !isNaN(calculator.phaseAngle) ?
                        parseFloat(calculator.phaseAngle.toFixed(2)) : 53.13
        }
    }
}
