import QtQuick 6.2
import QtQuick.Controls 6.2
import Qt.labs.qmlmodels 1.0
import QtQml 6.2
import QtQuick.Dialogs
import QtQuick.Layouts

import Python 1.0
    
    Page {
        
        header: ToolBar {
            id: toolbar
            RowLayout {
                anchors.fill: parent
                
                ToolButton {
                    id: row
                    text: qsTr("Add Row")
                    
                    onClicked: {
                        tableView.closeEditor()
                        pythonModel.appendRow()
                    }
                }
                ToolButton {
                    text: qsTr("Remove Row")
                    onClicked: {
                        if (pythonModel.rowCount() > 1) {
                            pythonModel.removeRows(pythonModel.rowCount() - 1)
                        }
                    }
                }
                ToolButton {
                    text: qsTr("Clear Rows")
                    onClicked: pythonModel.clearAllRows()
                }
                ToolButton {
                    text: qsTr("Load CSV")
                    onClicked: fileDialog.open()
                }
                Label {
                    text: "Voltage Drop Calculation"
                    elide: Label.ElideRight
                    horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            id: columnLayout
            width: 200
            anchors.left: parent.left

            Label {
                text: "Voltage Drop Threshold (%):"
            }
            TextField {
                id: voltageDropThresholdField
                text: "5"
                onTextChanged: pythonModel.voltageDropThreshold = text
            }

            Label {
                text: "Power Factor:"
            }
            TextField {
                id: powerFactorField
                text: "0.9"
                onTextChanged: pythonModel.powerFactor = text
            }

            Label {
                text: "Current:"
            }
            TextField {
                id: currentField
                text: "0"
                onTextChanged: pythonModel.current = text
            }
        }

        StackView {
            id: rect
            anchors.left: columnLayout.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top

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

            TableView {
                id: tableView
                anchors {
                    left: verticalHeader.right
                    top: horizontalHeader.bottom
                    right: parent.right
                    bottom: parent.bottom
                }
                
                clip: true
                interactive: true
                model: pythonModel
                selectionModel: ItemSelectionModel {}

                delegate: DelegateChooser {
                    role: "roleValue"

                    DelegateChoice {
                        roleValue: "dropdown"
                        delegate: ComboBox {
                            id: comboBox
                            implicitWidth: 100
                            implicitHeight: 50
                            model: pythonModel.cable_types

                            currentIndex: {
                                var modelData = TableView.view.model.data(TableView.view.index(row, column)).toString()
                                var index = model.indexOf(modelData)
                                return index !== -1 ? index : 0
                            }
                            onCurrentIndexChanged: {
                                TableView.view.model.setData(TableView.view.index(row, column), model[currentIndex])
                                for (var r = 0; r < TableView.view.model.rowCount(); r++) {
                                    var rowData = []
                                    for (var c = 0; c < TableView.view.model.columnCount(); c++) {
                                        rowData.push(TableView.view.model.data(TableView.view.model.index(r, c)))
                                    }
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "number"
                        delegate: Rectangle {
                            implicitWidth: 100
                            implicitHeight: 50
                            color: parseFloat(TableView.view.model.data(TableView.view.index(row, 6))) > pythonModel.voltageDropThreshold ? "red" : palette.base

                            Text {
                                anchors.centerIn: parent
                                text: display
                            }

                            TableView.editDelegate: TextField {
                                anchors.fill: parent
                                text: display

                                onTextChanged: {
                                    if (text !== display) {
                                        TableView.view.model.setData(TableView.view.index(row, column), text)
                                        display = text
                                    }
                                }

                                TableView.onCommit: {
                                    display = text
                                    focus = false
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: "button"
                        delegate: Button {
                            text: "Calculate"
                            onClicked: {
                                tableView.closeEditor()
                                pythonModel.calculateResistance(row)
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
                            // selectByMouse: true

                            onTextChanged: {
                                if (text !== display) {
                                    TableView.view.model.setData(TableView.view.index(row, column), text)
                                    display = text
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