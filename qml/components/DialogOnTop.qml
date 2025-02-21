import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import '../components'

import Python 1.0

Window {
    id: myWindow

    width: 200
    height: 200

    flags:  Qt.Window | Qt.WindowSystemMenuHint
            | Qt.WindowTitleHint | Qt.WindowMinimizeButtonHint
            | Qt.WindowMaximizeButtonHint | Qt.WindowStaysOnTopHint


    visible: true
    modality: Qt.NonModal // no need for this as it is the default value

        Pane {
        id: chart
        anchors.fill:parent
        
        // GridLayout {
        //     id: gridLayout
        //     anchors {
        //         left: parent.left
        //         right: parent.right
        //         top: parent.top
        //         bottom: tabledata.top
        //     }
        //     activeFocusOnTab: true
        //     flow: GridLayout.TopToBottom
        //     // rows: 2

        //     CellBox {
        //         id: cellBox
        //         Layout.fillHeight: true
        //         Layout.fillWidth: true
        //         // Layout.rowSpan: 2
        //         title: 'Charts'

        //         TabBar {
        //             id: bar
        //             width: parent.width
        //             TabButton { text: 'Chart' }
        //             TabButton { text: 'Results' }
        //         }

                // StackLayout {
                //     id: stacky
                //     width: parent.width
                //     anchors.top: bar.bottom
                //     anchors.bottom: parent.bottom
                //     currentIndex: bar.currentIndex

                    ChartView {
                        id: barChart
                        width: 500
                        height: 350
                        Layout.rowSpan: 10
                        title: "% Voltage Drop vs Cable Type"
                        antialiasing: true
                        legend.alignment: Qt.AlignBottom
                        titleFont {
                            pointSize: 13
                            bold: true
                        }

                        BarCategoryAxis {
                            id: axisX
                            // titleText: "Cable Type"
                        }

                        ValueAxis {
                            id: axisY
                            titleText: "Voltage Drop (%)"
                            min: 0
                            max: 10
                        }

                        // HoverHandler {
                        //     id: stylus
                        //     acceptedPointerTypes: PointerDevice.AllPointerTypes
                        // }

                        BarSeries {
                            id: barSeries
                            axisX: axisX
                            axisY: axisY
                            labelsVisible: true
                            labelsPosition: AbstractBarSeries.LabelsOutsideEnd
                            labelsPrecision: 2
                            labelsAngle: 90
                            labelsFormat: "@value %"
                            barWidth: 0.9

                            // onHovered: (status, index, barset) => {
                            //     if (status) {
                            //         tooltiptext.text = barset.label + ": " + barset.at(index).toFixed(2) + " V"
                            //         tooltip.visible = true
                            //         tooltip.x = stylus.point.position.x
                            //         tooltip.y = stylus.point.position.y - 20
                            //         tooltip.visible = true
                            //     } else {
                            //         tooltip.visible = false
                            //     }
                            // }
                        }

                        // Rectangle {
                        //     id: tooltip
                        //     visible: false
                        //     color: "#333"
                        //     radius: 5
                        //     opacity: 0.8
                        //     width: 100
                        //     height: 40
                        //     Text {
                        //         id: tooltiptext
                        //         anchors.fill: parent
                        //         text: ""
                        //         font.pixelSize: 14
                        //         color: "white"
                        //         font.bold: true
                        //         horizontalAlignment: Text.AlignHCenter
                        //         verticalAlignment: Text.AlignVCenter
                        //     }
                        // }
                    }
        //         }
        //     }
        // }

        // Row {
        //     id: tabledata
        //     width: parent.width
        //     anchors {
        //         bottom: parent.bottom
        //         right: parent.right
        //         left: parent.left
        //     }
            
        //     height: 20

        //     Label {
        //         id: currentxyposition
        //         text: pythonModel.cable_type
        //         font.bold: true
        //         Layout.alignment: Qt.AlignLeft
        //     }

        //     Text {
        //         id: desc
        //         text: " : " + pythonModel.voltage_drop.toFixed(1) + "V, " + pythonModel.percentage_drop.toFixed(1) + "%"
        //     }
        // }
    }
}