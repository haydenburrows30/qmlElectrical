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
    // Define calculator data model (sorted alphabetically by name)
    property var calculators: [
        { name: "Battery Calculator", source: "../components/calculators/BatteryCalculator.qml" },
        { name: "Cable Ampacity", source: "../components/calculators/CableAmpacityCalculator.qml" },
        { name: "Charging Current", source: "../components/calculators/ChargingCurrentCalculator.qml" },
        { name: "Discrimination Analyzer", source: "../components/calculators/DiscriminationAnalyzer.qml" },
        { name: "Harmonics Analysis", source: "../components/calculators/HarmonicsAnalyzer.qml" },
        { name: "Impedance Calculator", source: "../components/calculators/ImpedanceCalculator.qml" },
        { name: "Instrument Transformer", source: "../components/calculators/InstrumentTransformerCalculator.qml" },
        { name: "Motor Starting", source: "../components/calculators/MotorStartingCalculator.qml" },
        { name: "PF Correction", source: "../components/calculators/PowerFactorCorrection.qml" },
        { name: "Power Calculator", source: "../components/calculators/PowerCurrentCalculator.qml" },
        { name: "Protection Relay", source: "../components/calculators/ProtectionRelayCalculator.qml" },
        { name: "Transformer Calculator", source: "../components/calculators/TransformerCalculator.qml" },
        { name: "Unit Converter", source: "../components/calculators/UnitConverter.qml" },
        { name: "Voltage Drop", source: "../components/calculators/VoltageDropCalculator.qml" },
        { name: "Electric Machine", source: "../components/calculators/ElectricMachineCalculator.qml" },
        { name: "Earthing Calculator", source: "../components/calculators/EarthingCalculator.qml" },
        { name: "Transmission Line", source: "../components/calculators/TransmissionLineCalculator.qml" }
    ]

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

            Repeater {
                model: calculators
                delegate: CalcButton {
                    text: modelData.name
                    onClicked: {
                        calculatorLoader.setSource(modelData.source)
                    }
                }
            }
        }
    }
}