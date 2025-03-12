import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import "../components"
import "../components/calculators"

import "../"

Page {
    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: 10
        spacing: 10

        Label {
            text: "Select Calculator"
            font.pixelSize: 16
            font.bold: true
        }

        GridLayout {
            width: parent.width
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            CalcButton {
                text: "Power Calculator"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/PowerCurrentCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "PF Correction"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/PowerFactorCorrection.qml")
                    
                }
            }

            CalcButton {
                text: "Harmonics Analysis"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/HarmonicsAnalyzer.qml")
                    
                }
            }

            CalcButton {
                text: "Voltage Drop"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/VoltageDropCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Cable Ampacity"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/CableAmpacityCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Charging Current"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/ChargingCurrentCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Protection Relay"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/ProtectionRelayCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Relay Coordination"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/RelayCoordination.qml")
                    
                }
            }

            CalcButton {
                text: "Instrument Transformer"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/InstrumentTransformerCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Impedance Calculator"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/ImpedanceCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Battery Calculator"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/BatteryCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Transformer Calculator"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/TransformerCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Sine Calculator"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/SineCalculator.qml")
                    
                }
            }

            CalcButton {
                text: "Unit Converter"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/UnitConverter.qml")
                    
                }
            }

             CalcButton {
                text: "Discrimination Analyzer"
                onClicked: {
                    calculatorLoader.setSource("../components/calculators/DiscriminationAnalyzer.qml")
                    
                }
            }
        }
    }
}