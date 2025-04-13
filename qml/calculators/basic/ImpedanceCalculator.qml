import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/visualizers/"
import "../../components/style"
import "../../components/popups"

import Impedance 1.0

Item {
    id: fault_current

    property ImpedanceCalculator calculator: ImpedanceCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        parentCard: results
        popupText: "<h3> Impedance Calculator </h3><br>" +
                "Impedance is the total opposition to the flow of alternating current in a circuit. <br>" + 
                "It is the vector sum of resistance and reactance. The impedance is calculated using the formula Z = √(R² + X²) where R is the resistance and X is the reactance. <br>" + 
                "The phase angle is calculated using the formula θ = arctan(X / R) where θ is the phase angle, R is the resistance, and X is the reactance."
        widthFactor: 0.4
        heightFactor: 0.4
    }

    RowLayout {
        anchors.centerIn: parent
        anchors.margins: 10

        WaveCard {
            title: "Impedance Calculator"
            Layout.minimumHeight: 300
            Layout.minimumWidth: 300
            Layout.alignment: Qt.AlignTop
        
            GridLayout {
                anchors.centerIn: parent
                columns: 2

                Label {
                    text: "Resistance(R):"
                    Layout.preferredWidth: 100
                }
                TextFieldRound {
                    id: rInput
                    placeholderText: "Enter Resistance"
                    onTextChanged: {
                        if (text && calculator) {
                            calculator.setResistance(parseFloat(text))
                        }
                    }
                    Layout.preferredWidth: 140
                    Layout.alignment: Qt.AlignRight
                }

                Label {
                    text: "Reactance (X):"
                    Layout.preferredWidth: 100
                }
                TextFieldRound {
                    id: reactanceInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Reactance"
                    onTextChanged: {
                        if (text && calculator) {
                            calculator.setReactance(parseFloat(text))
                        }
                    }
                }

                Label {
                    text: "Impedance (Z):"
                    Layout.preferredWidth: 110
                }
                TextFieldBlue {
                    text: calculator && !isNaN(calculator.impedance) ? calculator.impedance.toFixed(2) + "Ω" : "0.00Ω"
                }
            }
        }

        WaveCard {
            id: results
            Layout.minimumHeight: 300
            Layout.minimumWidth: 300

            showSettings: true
            
            ImpedanceVectorViz {
                id: impedanceViz
                anchors.fill: parent
                anchors.margins: 2
                resistance: parseFloat(rInput.text || "3")
                reactance: parseFloat(reactanceInput.text || "4")
                impedance: calculator && !isNaN(calculator.impedance) ? 
                           parseFloat(calculator.impedance.toFixed(2)) : 5.0
                phaseAngle: calculator && !isNaN(calculator.phaseAngle) ?
                            parseFloat(calculator.phaseAngle.toFixed(2)) : 53.13
                darkMode: Universal.theme === Universal.Dark
                textColor: fault_current.textColor
            }
        }
    }
}
