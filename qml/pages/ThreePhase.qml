import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Sine 1.0

import "../components"

Page {
    id: root

    background: Rectangle {
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            
            RowLayout {
                id: mainLayout
                width: scrollView.width
                anchors.left: parent.left
                spacing: 5

                ColumnLayout {
                    WaveControls {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 280
                        model: sineModel
                    }

                    WaveCard {
                        title: "Waveform"
                        Layout.fillWidth: true
                        Layout.minimumWidth: 800
                        Layout.minimumHeight: 400
                        showInfo: false
                        
                        WaveChart {
                            anchors.fill: parent
                            model: sineModel
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    WaveCard {
                        title: "Measurements & Analysis"
                        Layout.minimumHeight: 280
                        Layout.minimumWidth: 530
                        showInfo: false

                        ColumnLayout {
                            anchors.fill: parent

                            Measurements {
                                Layout.fillWidth: true
                                model: sineModel
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Phasor Diagram"
                        Layout.minimumWidth: 530
                        Layout.fillHeight: true
                        showInfo: false
                        
                        PhasorDiagram {
                            anchors.fill: parent
                            phaseAngles: [
                                sineModel.phaseAngleA,
                                sineModel.phaseAngleB,
                                sineModel.phaseAngleC
                            ]
                            onAngleChanged: function(index, angle) {
                                switch(index) {
                                    case 0: sineModel.setPhaseAngleA(angle); break;
                                    case 1: sineModel.setPhaseAngleB(angle); break;
                                    case 2: sineModel.setPhaseAngleC(angle); break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
