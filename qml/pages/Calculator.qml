import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../components"
import "../components/calculators"

import "../"

import PCalculator 1.0
import Charging 1.0
import Fault 1.0
import Sine 1.0
import RLC 1.0
import VDrop 1.0
import Results 1.0
import Conversion 1.0
import CableAmpacity 1.0
import ProtectionRelay 1.0
import InstrumentTransformer 1.0
import DiscriminationAnalyzer 1.0
import HarmonicAnalysis 1.0
import PFCorrection 1.0
import Battery 1.0
import Machine 1.0

Page {
    id: home

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    property var calculatorList: [
        "../components/CalculatorMenu.qml",
        "../components/calculators/BatteryCalculator.qml",
        "../components/calculators/CableAmpacityCalculator.qml",
        "../components/calculators/ChargingCurrentCalculator.qml",
        "../components/calculators/DiscriminationAnalyzer.qml",
        "../components/calculators/EarthingCalculator.qml",
        "../components/calculators/ElectricMachineCalculator.qml",
        "../components/calculators/HarmonicsAnalyzer.qml",
        "../components/calculators/ImpedanceCalculator.qml",
        "../components/calculators/InstrumentTransformerCalculator.qml",
        "../components/calculators/MotorStartingCalculator.qml",
        "../components/calculators/PowerCurrentCalculator.qml",
        "../components/calculators/PowerFactorCorrection.qml",
        "../components/calculators/ProtectionRelayCalculator.qml",
        "../components/calculators/TransformerCalculator.qml",
        "../components/calculators/TransmissionLineCalculator.qml",
        "../components/calculators/UnitConverter.qml",
        "../components/calculators/VoltageDropCalculator.qml"
    ]
    property int currentCalculatorIndex: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        RowLayout {
            anchors.margins: 5
            Layout.fillWidth: true
            spacing: 10

            CalcButton {
                text: "←"
                Layout.maximumWidth: 40
                onClicked: {
                    currentCalculatorIndex = (currentCalculatorIndex - 1 + calculatorList.length) % calculatorList.length
                    calculatorLoader.setSource(calculatorList[currentCalculatorIndex])
                }
            }

            CalcButton {
                text: calculatorLoader.source.toString().split("/").pop().replace(".qml", "")
                Layout.preferredWidth: 200
                Layout.fillWidth: true
                onClicked: {
                    calculatorLoader.setSource(calculatorList[0])
                }
            }
            CalcButton {
                text: "→"
                Layout.maximumWidth: 40
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    currentCalculatorIndex = (currentCalculatorIndex + 1) % calculatorList.length
                    calculatorLoader.setSource(calculatorList[currentCalculatorIndex])
                }
            } 
        }

        Loader {
            id: calculatorLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: "../components/CalculatorMenu.qml"
        }
    }
}