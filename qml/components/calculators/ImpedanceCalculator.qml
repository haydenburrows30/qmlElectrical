import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import Fault 1.0  // Import the correct namespace for the fault current calculator

WaveCard {
    id: fault_current
    title: 'Impedance'
    // No need to set color property as WaveCard already handles theme colors

    // Create a local instance of our calculator
    property FaultCurrentCalculator calculator: FaultCurrentCalculator {}
    
    // Helper property for theme colors
    property color textColor: Universal.foreground

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
                    color: Universal.foreground  // Use theme foreground color
                }
            }
        }

        // Assuming ImpedanceVectorViz is a Canvas, update it to support themes
        Rectangle {
            Layout.minimumWidth: 300
            Layout.minimumHeight: 300
            color: Universal.background
            border.color: Universal.foreground
            border.width: 1
            
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
                // Use property names that match what ImpedanceVectorViz expects
                darkMode: Universal.theme === Universal.Dark
                textColor: fault_current.textColor  // Use the property name defined in ImpedanceVectorViz
            }
        }
    }
}
