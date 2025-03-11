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

                CalcButton {
                    text: "Menu"
                    Layout.maximumWidth: 100
                    onClicked: {
                        calculatorLoader.setSource("../components/CalculatorMenu.qml")
                    }
                }

                Label {
                    text: "Current: " + (calculatorLoader.source.toString().split("/").pop().replace(".qml", ""))
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Loader {
            id: calculatorLoader
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: "../components/CalculatorMenu.qml"
        }
    }
}