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
import ConvCalc 1.0
import RLC 1.0
import VDrop 1.0
import Results 1.0
import SineCalc 1.0
import Transformer 1.0
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

            ScrollView {
                id: scrollView
                anchors.fill: parent
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                clip: true

                Row {
                    spacing: 2

                    Repeater {
                        model: ["Power Calculator", "Conversion Calculator", 
                               "Charging Current", "Impedance Calculator", 
                               "Frequency Calculator", "Sine Calculator",
                               "Transformer Calculator", "PF Correction",
                               "Cable Ampacity", "Motor Calculator",
                               "Protection Relay", "Instrument Transformer",
                               "Harmonics Analysis", "Relay Coordination",
                               "Voltage Drop", "Battery Calculator"]  // Added Battery Calculator
                        
                        Button {
                            required property int index
                            required property string modelData
                            
                            height: 40
                            width: 120  // Made buttons slightly narrower
                            text: modelData
                            
                            background: Rectangle {
                                color: calculatorLoader.source.toString().includes(getCalculatorSource(index)) ? 
                                      (sideBar.toggle1 ? "#404040" : "#d0d0d0") : 
                                      (sideBar.toggle1 ? "#2a2a2a" : "#e5e5e5")
                            }
                            
                            onClicked: calculatorLoader.setSource(getCalculatorSource(index))
                        }
                    }
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

    function getCalculatorSource(index) {
        switch (index) {
            case 0: return "../components/calculators/PowerCurrentCalculator.qml"
            case 1: return "../components/calculators/ConversionCalculator.qml"
            case 2: return "../components/calculators/ChargingCurrentCalculator.qml"
            case 3: return "../components/calculators/ImpedanceCalculator.qml"
            case 4: return "../components/calculators/FrequencyCalculator.qml"
            case 5: return "../components/calculators/SineCalculator.qml"
            case 6: return "../components/calculators/TransformerCalculator.qml"
            case 7: return "../components/calculators/PowerFactorCorrection.qml"
            case 8: return "../components/calculators/CableAmpacityCalculator.qml"
            case 9: return "../components/calculators/MotorCalculator.qml"
            case 10: return "../components/calculators/ProtectionRelayCalculator.qml"
            case 11: return "../components/calculators/InstrumentTransformerCalculator.qml"
            case 12: return "../components/calculators/HarmonicsAnalyzer.qml"
            case 13: return "../components/calculators/RelayCoordination.qml"
            case 14: return "../components/calculators/VoltageDropCalculator.qml"  // Added new case
            case 15: return "../components/calculators/BatteryCalculator.qml"  // Added new case
            default: return "../components/calculators/PowerCurrentCalculator.qml"
        }
    }
}