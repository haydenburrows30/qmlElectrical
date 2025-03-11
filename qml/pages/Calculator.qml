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

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5
            
            ColumnLayout {
                id: mainLayout
                width: scrollView.width
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 5

                PowerCurrentCalculator {
                    id: powerCalculator
                    // info: "../../media/powercalc.png"
                }

                ConversionCalculator {
                    id: conversionCalc
                }

                ChargingCurrentCalculator {
                    id: chargingCurrentCalc
                    // info: "../../media/ccc.png"
                }

                ImpedanceCalculator {
                    id: impedanceCalc
                    // info: "../../media/impedance_formula.png"
                }

                FrequencyCalculator {
                    id: frequencyCalc
                    // info: "../../media/resonant_frequency.png"
                }

                SineCalculator {
                    id: sineCalc
                }

                // TransformerCalculator {
                //     id: transformerCalc
                // }

                VoltageDropCalculator {
                    id: voltageDropCalc
                    // info: "../../media/voltage_drop.png"
                }

                MotorStartingCalculator {
                    id: motorCalc
                    // info: "../../media/motor_formula.png"
                }

                PowerFactorCorrection {
                    id: pfCalculator
                    // info: "../../media/pf_correction_formula.png"
                }

                CableAmpacityCalculator {
                    id: cableAmpacity
                    // info: "../../media/cable_ampacity_formula.png"
                }

                // ProtectionRelayCalculator {
                //     id: protectionRelayCalc
                // }

                HarmonicAnalyzer {
                    id: harmonicAnalysisCalc
                    // info: "../../media/thd_formula.png"
                }

                InstrumentTransformerCalculator {
                    id: instrumentTransformerCalc
                    // info: "../../media/ct_vt_formula.png"
                }

                RelayCoordination {
                    id: relayCoordination
                    // info: "../../media/relay_coordination.png"
                }

                DiscriminationAnalyzer {
                    id: discriminationAnalyzerCalc
                    // info: "../../media/discrimination.png"
                }
            }
        }
    }
}