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
//Popup Window
    DialogOnTop {
        id: chart
        visible:false
    }

    function updateChart() {

        // see if the object is empty
        if (Object.values(tableView.rowsadded).includes(tableView.rowvalue)) {
            console.log("clear rows to show new graph")
            }
        else {
            let maxPercentVoltageDrop = 0  // Track highest voltage drop
            //create series with rowvalue as the name

            let series = lineChart.createSeries(ChartView.SeriesTypeScatter,tableView.rowvalue,lineChart.axisx,lineChart.axisy)

            //apend the series with cable types.  Get the 
            for (let i = 0; i < pythonModel.chart_data_qml.length; i++) {
                let entry = pythonModel.chart_data_qml[i]

                lineChart.series(Object.keys(tableView.rowsadded).length).append(i, [entry.percentage_drop])

                // Track the highest voltage drop to set the Y-axis max value
                if (entry.percentage_drop > maxPercentVoltageDrop) {
                    maxPercentVoltageDrop = entry.percentage_drop
                }
            }
            series.pointLabelsVisible = true

            series.pointsVisible = true
            series.pointLabelsFont.pointSize = 14
            series.pointLabelsFormat = "@yPoint %"
            series.pointLabelsClipping = false
            series.style = Qt.NoPen
            series.width = 5
            series.selectedColor = "red"

            // init no of series in lineChart
            let noseries = lineChart.count
            // create an object with linechart_series:row_number
            tableView.rowsadded[noseries] = tableView.rowvalue

            // Dynamically adjust Y-axis scale
            lineChart.axisy.max = maxPercentVoltageDrop * 1.4  // Add 20% buffer for visibility
            lineChart.axisy.min = 0
        }
    }

    function updateBarChart() {
        
        if (draggablePanel.barChart.barSeries.count > 0) {
            draggablePanel.barChart.barSeries.clear()
        }
        let categories = []
        let maxPercentVoltageDrop = 0  // Track highest voltage drop

        for (let i = 0; i < pythonModel.chart_data_qml.length; i++) {
            let entry = pythonModel.chart_data_qml[i]
            // create new barset for each cable type
            let example = draggablePanel.barChart.barSeries.append(entry.cable, [entry.percentage_drop])
            // set label font and colour
            example.labelFont = Qt.font({pointSize: 12}); //bold:true
            example.labelColor = "black"

            // Track the highest voltage drop to set the Y-axis max value
            if (entry.percentage_drop > maxPercentVoltageDrop) {
                maxPercentVoltageDrop = entry.percentage_drop
            }
        }

        draggablePanel.barChart.axisX1.categories = ["Aluminium"] // ,"Copper"

        // Dynamically adjust Y-axis scale
        draggablePanel.barChart.axisY1.max = maxPercentVoltageDrop * 1.4  // Add 20% buffer for visibility
        draggablePanel.barChart.axisY1.min = 0
    }

    MouseArea {
        id: area
        anchors.fill: parent

        onClicked:  {
            sideBar.close()
            }
    }
//Popup Menu
    MenuPanel {
        id: draggablePanel
        x: Math.round((window.width - width) / 2)
        y: Math.round(window.height / 6)
        width: 400
        height: 400
        z: 99
        visible: false
        DragHandler {
            xAxis.minimum: 0
            yAxis.minimum: 0
            xAxis.maximum: voltage_drop.width - draggablePanel.width
            yAxis.maximum: voltage_drop.height - draggablePanel.height
        }

        DesignEffect {
            backgroundBlurRadius: 500
            backgroundLayer: parent
            effects: [
                DesignDropShadow {}
            ]
        }
    }
//Settings
    GroupBox {
        id: settings
        title: 'Settings'
        width: 250
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10
        Component.onCompleted: {
            settings.width = columnLayout.width + 25
        }
        
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
                    ToolTip {
                        text: "Power Factor"
                    }
                }

                Text {
                    text: powerFactorSlider.value.toFixed(2)
                    color: Universal.theme
                }
            }
            // Button {
            //     text: "Options"
            //     Layout.fillWidth: true

            //     ToolTip {
            //         text: "Options"
            //     }
            //     onClicked: {
            //         draggablePanel.visible == false ? draggablePanel.visible = true:draggablePanel.visible = false
            //     }
            // }
        }
    }

//Table
    GroupBox {
        id: table
        title: 'Table'
        width: 960
        height: 180
        anchors {
            left: settings.right
            top: parent.top
            leftMargin: 20
            topMargin: 10
        }
        
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
                    table.height = table.height + 51
                }

                ToolTip {
                    text: "Add Row"
                }
            }
            Button {
                text: qsTr("Remove Row")
                onClicked: {
                    if (pythonModel.rowCount() > 1 && tableView.currentRow > 0) {
                        pythonModel.removeRows(tableView.currentRow)
                        lineChart.removeSeries(lineChart.series(tableView.currentRow +1));
                        rect.height = rect.height - 51
                        table.height = table.height - 51
                    }
                }
                 Layout.fillWidth: true

                 ToolTip {
                    text: "Remove Row"
                }
            }
            Button {
                text: qsTr("Clear Rows")
                onClicked: {
                    rect.height = 85
                    table.height = 180
                    pythonModel.clearAllRows()
                    lineChart.removeAllSeries()
                    draggablePanel.barChart.barSeries.clear()
                    tableView.rowsadded = []
                }
                Layout.fillWidth: true

                ToolTip {
                    text: "Clear all rows"
                }
            }
            Button {
                text: qsTr("Load CSV")
                onClicked: fileDialog.open()
                Layout.fillWidth: true
                ToolTip {
                    text: "Load csv"
                }
            }
        }

        Rectangle {
            id: rect
            anchors.top: buttons.bottom
            anchors.topMargin: 10
            width: 930
            height: 85

            color: toolBar.toggle ? palette.base : palette.dark

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
//LineChart
    LineChart {
        id: lineChart
        anchors.top: table.bottom
        anchors.bottom: parent.bottom
        anchors.left: settings.right
        width: table.width
        currentrow: tableView.currentRow
    }
}