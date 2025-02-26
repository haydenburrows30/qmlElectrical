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

    property int rowvalue: 0
    property var rowsadded: ({})
    property int rowselected: tableView.currentRow
    property int previousrow

    function updateChart() {

        // see if the object is empty
        if (Object.values(rowsadded).includes(rowvalue)) {
            console.log("clear rows to show new graph")
            }
        else {
            let maxPercentVoltageDrop = 0  // Track highest voltage drop
            //create series with rowvalue as the name

            let series = lineChart.createSeries(ChartView.SeriesTypeScatter,rowvalue,lineChart.axisx2,lineChart.axisy2)

            //apend the series with cable types.  Get the 
            for (let i = 0; i < pythonModel.chart_data_qml.length; i++) {
                let entry = pythonModel.chart_data_qml[i]

                lineChart.series(Object.keys(rowsadded).length).append(i, [entry.percentage_drop])

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
            rowsadded[noseries] = rowvalue

            // Dynamically adjust Y-axis scale
            lineChart.axisy2.max = maxPercentVoltageDrop * 1.4  // Add 20% buffer for visibility
            lineChart.axisy2.min = 0
        }
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
        width: 250
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
                        // pythonModel.update_chart(0)
                        // updateChart()
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
            Button {
                text: "Options"
                Layout.fillWidth: true

                ToolTip {
                    text: "Options"
                }
                onClicked: {
                    draggablePanel.visible == false ? draggablePanel.visible = true:draggablePanel.visible = false
                    // chart.visible = true

                }
            }
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
                        // delete rowsadded[tableView.currentRow]
                        // console.log(rowsadded)
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
                    rowsadded = []
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
                
                clip: true
                interactive: false
                model: pythonModel
                selectionModel: ItemSelectionModel {}

                animate: false

                columnSpacing: 1
                rowSpacing: 1

                onCurrentRowChanged: {
                    if (lineChart.count > tableView.currentRow && tableView.currentRow !== -1) {
                    lineChart.series(tableView.currentRow).color = "red"
                    console.log (tableView.currentRow,lineChart.count)
                    }
                }

                delegate: DelegateChooser {
                    role: "roleValue"

                    DelegateChoice {
                        roleValue: "dropdown"
                        delegate: ComboBox {
                            id: comboBox
                            implicitWidth: 100
                            implicitHeight: 50
                            flat: true
                            model: pythonModel ? pythonModel.cable_types : []

                            background: Rectangle {
                                implicitWidth: 120
                                implicitHeight: 40
                                // border.width: comboBox.visualFocus ? 2 : 1
                                color: palette.base
                                radius: 2
                            }

                            currentIndex: {
                                var modelData = TableView.view.model ? TableView.view.model.data(TableView.view.index(row, column)).toString() : ""
                                var index = model.indexOf(modelData)
                                return index !== -1 ? index : 0
                            }
                            onCurrentIndexChanged: {
                                if (TableView.view.model) {
                                    TableView.view.model.setData(TableView.view.index(row, column), model[currentIndex])
                                    for (var r = 0; r < TableView.view.model.rowCount(); r++) {
                                        var rowData = []
                                        for (var c = 0; c < TableView.view.model.columnCount(); c++) {
                                            rowData.push(TableView.view.model.data(TableView.view.model.index(r, c)))
                                        }
                                    }
                                }
                                pythonModel.calculateResistance(row)
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "number"
                        delegate: Rectangle {
                            implicitWidth: 120
                            implicitHeight: 50
                            color: current ? palette.dark : palette.base

                            required property bool selected
                            required property bool current

                            Text {
                                anchors.centerIn: parent
                                text: display
                            }

                            TableView.editDelegate: TextField {
                                anchors.fill: parent
                                text: display

                                onTextChanged: {
                                    if (text !== display) {
                                        if (TableView.view.model) {
                                            TableView.view.model.setData(TableView.view.index(row, column), text)
                                            display = text
                                        }
                                    }
                                    pythonModel.calculateResistance(row)
                                }

                                TableView.onCommit: {
                                    display = text
                                    focus = false
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "result"
                        delegate: Rectangle {
                            implicitWidth: 120
                            implicitHeight: 50
                            color: TableView.view.model && parseFloat(TableView.view.model.data(TableView.view.index(row, 6))) > pythonModel.voltageDropThreshold ? "red" : palette.base

                            Text {
                                anchors.centerIn: parent
                                text: display
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "button"
                        delegate: Button {
                            text: "Add Chart"
                            onClicked: {
                                rowvalue = row
                                pythonModel.update_chart(row)
                                updateChart()
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "resistance"
                        delegate: TextField {
                            implicitWidth: 100
                            implicitHeight: 50
                            text: display
                            readOnly: true
                        }
                    }

                    DelegateChoice {
                        roleValue: "length"
                        delegate: TextField {
                            implicitWidth: 100
                            implicitHeight: 50
                            text: display

                            onTextChanged: {
                                if (text !== display) {
                                    if (TableView.view.model) {
                                        TableView.view.model.setData(TableView.view.index(row, column), text)
                                        display = text
                                    }
                                }
                            }

                            TableView.onCommit: {
                                display = text
                                focus = false
                            }
                        }
                    }
                }
            }
        }
    }

    LineChart {
        id: lineChart
        anchors.top: table.bottom
        anchors.bottom: parent.bottom
        anchors.left: settings.right
        width: table.width
        currentrow: tableView.currentRow
    }
}