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

TableView {
    id: tableView

    property int rowvalue: 0
    property var rowsadded: ({})
    // property int rowselected: tableView.currentRow
    
    clip: true
    interactive: false
    model: pythonModel
    selectionModel: ItemSelectionModel {}

    animate: false

    columnSpacing: 1
    rowSpacing: 1

    delegate: DelegateChooser {
        role: "roleValue"

        DelegateChoice {
            roleValue: "dropdown"
            delegate: ComboBox {
                id: comboBox
                implicitWidth: 100
                implicitHeight: 50
                // flat: true
                model: pythonModel ? pythonModel.cable_types : []

                // background: Rectangle {
                //     implicitWidth: 120
                //     implicitHeight: 40
                //     color: palette.base
                //     radius: 2
                // }

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
                implicitWidth: 95
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
                implicitWidth: 95
                implicitHeight: 50
                color: TableView.view.model && parseFloat(TableView.view.model.data(TableView.view.index(row, 6))) > pythonModel.voltageDropThreshold ? "red" : palette.base

                Text {
                    anchors.centerIn: parent
                    text: display
                }
            }
        }

        DelegateChoice {
            roleValue: "button1"
            delegate: Button {
                icon.name: "LightBar"
                icon.width: 30
                icon.height: 30
                onClicked: {
                    rowvalue = row
                    pythonModel.update_chart(row)
                    updateBarChartMain()
                }

                AToolTip {
                        text: "Add to main chart"
                    }
            }
        }

        DelegateChoice {
            roleValue: "button2"
            delegate: Button {
                icon.name: "DarkBar"
                icon.width: 30
                icon.height: 30
                onClicked: {
                    rowvalue = row
                    pythonModel.update_chart(row)
                    updateBarChartPopUp()
                    draggablePanel.visible = true
                }

                AToolTip {
                        text: "Add to popup chart"
                    }
            }
        }

        // DelegateChoice {
        //     roleValue: "length"
        //     delegate: TextField {
        //         implicitWidth: 100
        //         implicitHeight: 50
        //         text: display

        //         onTextChanged: {
        //             if (text !== display) {
        //                 if (TableView.view.model) {
        //                     TableView.view.model.setData(TableView.view.index(row, column), text)
        //                     display = text
        //                 }
        //             }
        //             pythonModel.calculateResistance(row)
        //         }

        //         TableView.onCommit: {
        //             display = text
        //             focus = false
        //         }
        //     }
        // }
    }
}