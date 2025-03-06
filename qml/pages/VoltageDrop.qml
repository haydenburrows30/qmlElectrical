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
    
Page {
    id: voltage_drop

    background: Rectangle {
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
    }

    function updateBarChartPopUp() {
        
        if (draggablePanel.barChart.barSeries.count > 0) {
            draggablePanel.barChart.barSeries.clear()
        }
        let categories = []
        let maxPercentVoltageDrop = 0 

        for (let i = 0; i < pythonModel.chart_data_qml.length; i++) {
            let entry = pythonModel.chart_data_qml[i]
            // create new barset for each cable type
            let example = draggablePanel.barChart.barSeries.append(entry.cable, [entry.percentage_drop])

            example.labelFont = Qt.font({pointSize: 12});
            if (toolBar.toggle) {
            example.labelColor = "white"
            } else example.labelColor = "black"

            // Track the highest voltage drop to set the Y-axis max value
            if (entry.percentage_drop > maxPercentVoltageDrop) {
                maxPercentVoltageDrop = entry.percentage_drop
            }
        }

        draggablePanel.barChart.title = "Row " + tableView.rowvalue + " Voltage Drop"
        draggablePanel.barChart.axisX1.categories = ["Aluminium"] // ,"Copper"
        draggablePanel.barChart.axisY1.max = maxPercentVoltageDrop * 1.4 
        draggablePanel.barChart.axisY1.min = 0
    }

    function updateBarChartMain() {
        
        if (barChart.barSeries.count > 0) {
            barChart.barSeries.clear()
        }

        let categories = []
        let maxPercentVoltageDrop = 0  

        for (let i = 0; i < pythonModel.chart_data_qml.length; i++) {
            let entry = pythonModel.chart_data_qml[i]
            let example = barChart.barSeries.append(entry.cable, [entry.percentage_drop])

            example.labelFont = Qt.font({pointSize: 12});

            if (toolBar.toggle) {
            example.labelColor = "white"
            } else example.labelColor = "black"

            if (entry.percentage_drop > maxPercentVoltageDrop) {
                maxPercentVoltageDrop = entry.percentage_drop
            }
        }

        barChart.title = "Row " + tableView.rowvalue + " Voltage Drop"
        barChart.axisX1.categories = ["Aluminium"] 
        barChart.axisY1.max = maxPercentVoltageDrop * 1.4  
        barChart.axisY1.min = 0
    }

//Popup Menu
    DialogOnTop {
        id: draggablePanel
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
                anchors.left: parent.left
                spacing: 5

                //Settings
                WaveCard {
                    id: settings
                    title: 'Settings'
                    Layout.minimumHeight: 200
                    Layout.minimumWidth: 300
                    Layout.alignment: Qt.AlignTop

                    showInfo: false
                    
                    ColumnLayout {
                        id: columnLayout

                        Label {
                            text: "Voltage Drop Threshold (%):"
                        }
                        TextField {
                            id: voltageDropThresholdField
                            text: "5"
                            onTextChanged: pythonModel.voltageDropThreshold = text
                            Layout.fillWidth: true

                            ToolTip {
                                text: "Voltage Drop Threshold"
                            }
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
                                    pythonModel.calculateResistance(tableView.currentRow)
                                }
                                AToolTip {
                                    text: "Select row to change power Factor"
                                }
                            }

                            Text {
                                text: powerFactorSlider.value.toFixed(2)
                                color: Universal.theme
                            }
                        }
                    }
                }

                ColumnLayout {
                    //Table
                    WaveCard {
                        id: table
                        title: 'Table'
                        Layout.minimumHeight: 200
                        Layout.minimumWidth: 810

                        showInfo: false
                        
                        RowLayout {
                            id: buttons
                            width: parent.width
                            anchors.bottomMargin: 10

                            Button {
                                text: qsTr("Add Row")
                                Layout.fillWidth: true
                                onClicked: {
                                    tableView.closeEditor()
                                    pythonModel.appendRow()
                                    rect.height = rect.height + 51
                                    table.Layout.minimumHeight = table.Layout.minimumHeight + 51
                                }

                                AToolTip {
                                    text: "Add Row"
                                }
                            }
                            Button {
                                text: qsTr("Remove Row")
                                onClicked: {
                                    if (pythonModel.rowCount() > 1 && tableView.currentRow > 0) {
                                        pythonModel.removeRows(tableView.currentRow)
                                        rect.height = rect.height - 51
                                        table.Layout.minimumHeight = table.Layout.minimumHeight - 51
                                    }
                                }
                                Layout.fillWidth: true

                                AToolTip {
                                    text: "Remove Row"
                                }
                            }
                            Button {
                                text: qsTr("Clear Rows")
                                Layout.fillWidth: true
                                onClicked: {
                                    rect.height = 85
                                    table.Layout.minimumHeight = 200
                                    pythonModel.clearAllRows()
                                    draggablePanel.barChart.barSeries.clear()
                                    barChart.barSeries.clear()
                                }
                                
                                AToolTip {
                                    text: "Clear all rows"
                                }
                            }
                            Button {
                                text: qsTr("Load CSV")
                                onClicked: fileDialog.open()
                                Layout.fillWidth: true

                                AToolTip {
                                    text: "Load csv"
                                }
                            }
                        }

                        Rectangle {
                            id: rect
                            anchors.top: buttons.bottom
                            anchors.topMargin: 10
                            width: parent.width
                            height: 85

                            color: toolBar.toggle ? Qt.darker(palette.base,2) : palette.dark

                            HorizontalHeaderView {
                                id: horizontalHeader
                                anchors.left: tableView.left
                                anchors.top: parent.top
                                syncView: tableView
                                clip: true
                            }

                            VerticalHeaderView {
                                id: verticalHeader
                                anchors.top: tableView.top
                                anchors.left: parent.left
                                syncView: tableView
                                clip: true
                            }

                            // box to cover in the left upper corner

                            Rectangle {
                                z: 99
                                anchors.left: parent.left
                                anchors.top: parent.top
                                width: verticalHeader.width
                                height: horizontalHeader.height
                                color: toolBar.toggle ?  "black":"white"
                                Text {
                                    text: "#"
                                    horizontalAlignment : Text.AlignHCenter
                                    verticalAlignment :  Text.AlignVCenter
                                    color: toolBar.toggle ?  "white":"black"
                                    width: parent.width
                                    height: parent.height
                                }
                            }

                            TableView {
                                id: tableView
                                anchors {
                                    left: verticalHeader.right
                                    top: horizontalHeader.bottom
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                            }
                        }
                    }

                    WaveCard {
                        title: 'Voltage Drop Chart'
                        //BarChart
                        Layout.minimumHeight: 500
                        // Layout.minimumWidth: 800
                        Layout.fillWidth: true

                        showInfo: false

                        BarChart {
                            id: barChart
                            anchors.fill: parent
                            
                        }
                    }
                }
            }
        }
    }
}