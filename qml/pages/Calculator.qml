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

import PCalculator 1.0
import Charging 1.0
import Fault 1.0
import Sine 1.0
import RFreq 1.0
import RLC 1.0
import VDrop 1.0
import Results 1.0
import SineCalc 1.0
import Conversion 1.0
import CableAmpacity 1.0
import ProtectionRelay 1.0
import InstrumentTransformer 1.0
import RelayCoordination 1.0
import DiscriminationAnalyzer 1.0
import OvercurrentCurves 1.0
import HarmonicAnalysis 1.0
import PFCorrection 1.0
import Motor 1.0

Page {
    id: home

    property var powerTriangleModel
    property var impedanceVectorModel

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: sideBar.toggle1 ? "#2a2a2a" : "#e5e5e5"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 10

                Label {
                    text: "Current: " + (calculatorLoader.source.toString().split("/").pop().replace(".qml", ""))
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Button {
                    text: "Select Calculator"
                    icon.name: "menu"
                    onClicked: calculatorMenu.open()
                }
            }
        }

        Loader {
            id: calculatorLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: "../components/calculators/PowerCurrentCalculator.qml"
        }
    }

    Popup {
        id: calculatorMenu
        width: 600
        height: 400
        anchors.centerIn: parent
        modal: true
        
        background: Rectangle {
            color: sideBar.toggle1 ? "#2a2a2a" : "#ffffff"
            border.color: sideBar.toggle1 ? "#404040" : "#d0d0d0"
            radius: 5
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Label {
                text: "Select Calculator"
                font.pixelSize: 16
                font.bold: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridLayout {
                    width: parent.width
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    CalcButton {
                        text: "Power Calculator"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/PowerCurrentCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "PF Correction"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/PowerFactorCorrection.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Harmonics Analysis"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/HarmonicsAnalyzer.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Voltage Drop"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/VoltageDropCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Cable Ampacity"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/CableAmpacityCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Charging Current"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/ChargingCurrentCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Protection Relay"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/ProtectionRelayCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Relay Coordination"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/RelayCoordination.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Instrument Transformer"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/InstrumentTransformerCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Impedance Calculator"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/ImpedanceCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Battery Calculator"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/BatteryCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Transformer Calculator"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/TransformerCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Sine Calculator"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/SineCalculator.qml")
                            calculatorMenu.close()
                        }
                    }

                    CalcButton {
                        text: "Unit Converter"
                        onClicked: {
                            calculatorLoader.setSource("../components/calculators/UnitConverter.qml")
                            calculatorMenu.close()
                        }
                    }
                }
            }
        }
    }
}