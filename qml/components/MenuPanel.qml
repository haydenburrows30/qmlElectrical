import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal

import QtQuick.Studio.DesignEffects

Rectangle {
    id: menuPanel
    width: 250
    height: 400
    color: "transparent"

    Rectangle {
        id: background
        color: "#45d9d9d9"
        border.color: "#ededed"
        border.width: 1
        anchors.fill: parent
    }

    Rectangle {
        id: menuColumn
        color: "transparent"
        anchors.fill: parent
        anchors.topMargin: 10
        
        ColumnLayout {
            id: menuColumn_layout
            spacing: 5
            
            anchors.horizontalCenter: parent.horizontalCenter

            // Button {
            //     id: menuItem1
            //     text: "Draggable Panel"
            //     Layout.preferredWidth: 180
            //     Layout.preferredHeight: 50
            //     onClicked: {
            //         console.log("clicked1")
            //     }
            // }

            // Button {
            //     id: menuItem2
            //     text: "Draggable Panel"
            //     Layout.preferredWidth: 180
            //     Layout.preferredHeight: 50
            //     onClicked: {
            //         console.log("clicked1")
            //     }
            // }

            Label {
                text: "Voltage Drop Threshold (%):"
            }
            TextField {
                id: voltageDropThresholdField
                text: "5"
                onTextChanged: pythonModel.voltageDropThreshold = text
                Layout.fillWidth: true
            }

            Label {
                text: "Power Factor:"
            }
            Row {
                Layout.fillWidth : true

                Slider {
                    id: powerFactorSlider
                    from: 0.5
                    to: 1.0
                    value: 0.8
                    stepSize: 0.01
                    onValueChanged: {
                        pythonModel.powerFactor = value
                        pythonModel.update_chart(0)
                        updateChart()
                        pythonModel.calculateResistance(0)
                    }
                }

                Text {
                    text: powerFactorSlider.value.toFixed(2)
                }
            }
        }
    }
}