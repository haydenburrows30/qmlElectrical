import QtQuick 6.2
import QtQuick.Controls 6.2
import Qt.labs.qmlmodels 1.0
import QtQml 6.2
import QtQuick.Dialogs

import Python 1.0

Window {
    id: window
    
    minimumWidth: 900
    minimumHeight: 400
    height: 400
    visible: true    

    PythonModel {
        id: pythonModel
    }

    FileDialog {
        id: fileDialog
        title: "Select CSV File"
        nameFilters: ["CSV Files (*.csv)"]
        onAccepted: {
            if (fileDialog.selectedFile) {
                voltageDropModel.load_csv_file(fileDialog.selectedFile.toString().replace("file://", ""))
            }
        }
    }

    Button {
        id: addRowButton
        text: "Add Row"
        anchors.top: parent.top
        anchors.left: parent.left
        focusPolicy: Qt.ClickFocus
        onClicked: {
            // forces the editor to close which takes focus away from the editor
            tableView.closeEditor()
            // Clear focus for ComboBox and TextField
            tableView.children.forEach(child => {
                if (child instanceof TextField) {
                    child.editingFinished()  // Force editing finished
                }
                if (child instanceof ComboBox || child instanceof TextField) {
                    child.clearFocus()  // Clear focus
                }
            })
            pythonModel.appendRow()
        }
    }

    Button {
        id: deleteLastRowButton
        text: "Delete Last Row"
        anchors.top: parent.top
        anchors.left: addRowButton.right
        onClicked: {
            if (pythonModel.rowCount() > 1) {
                pythonModel.removeRows(pythonModel.rowCount() - 1)
            }
        }
    }

    Button {
        id: clearAllRowsButton
        text: "Clear All Rows"
        anchors.top: parent.top
        anchors.left: deleteLastRowButton.right
        onClicked: {
            pythonModel.clearAllRows()
        }
    }

    Button {
        id: loadCSVButton
        text: "Load CSV"
        anchors.top: parent.top
        anchors.left: clearAllRowsButton.right
        onClicked: fileDialog.open()
    }

    Rectangle {
        id: rect
        anchors.top: addRowButton.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        color: Application.styleHints.appearance === Qt.Light ? palette.mid : palette.midlight

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
            anchors.left: verticalHeader.right
            anchors.top: horizontalHeader.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            interactive: true
            rowSpacing: 1
            columnSpacing: 1
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
                        // get comboBox index from model data of voltagedropmodel
                        model: pythonModel.cable_types
                        currentIndex: {
                            var modelData = TableView.view.model.data(TableView.view.index(row, column)).toString()
                            var index = model.indexOf(modelData)
                            return index !== -1 ? index : 0
                        }
                        onCurrentIndexChanged: {
                            TableView.view.model.setData(TableView.view.index(row, column), model[currentIndex])
                            // console.log("Table Data:")
                            for (var r = 0; r < TableView.view.model.rowCount(); r++) {
                                var rowData = []
                                for (var c = 0; c < TableView.view.model.columnCount(); c++) {
                                    rowData.push(TableView.view.model.data(TableView.view.model.index(r, c)))
                                }
                                // console.log("Row " + r + ": " + rowData.join(", "))
                            }
                        }
                    }
                }

                DelegateChoice {
                    roleValue: "number"
                    delegate: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 50
                        color: palette.base
                        Component.onCompleted: {window.width = rect.width}

                        Text {
                            anchors.centerIn: parent
                            text: display
                        }

                        TableView.editDelegate: TextField {
                            anchors.fill: parent
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            text: display

                            onTextChanged: {
                                if (text !== display) {
                                    TableView.view.model.setData(TableView.view.index(row, column), text)
                                    display = text
                                }
                            }

                            TableView.onCommit: {
                                display = text
                                focus = false  // Clear focus after committing changes
                            }

                            onEditingFinished: {
                                focus = false  // Clear focus after editing is finished
                            }
                        }
                    }
                }

                DelegateChoice {
                    roleValue: "button"
                    delegate: Button {
                        text: "Calculate"
                        onClicked: {
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

                        onTextChanged: {
                            if (text !== display) {
                                TableView.view.model.setData(TableView.view.index(row, column), text)
                                display = text
                            }
                        }

                        TableView.onCommit: {
                            display = text
                            focus = false  // Clear focus after committing changes
                        }

                        onEditingFinished: {
                            focus = false  // Clear focus after editing is finished
                        }
                    }
                }
            }
        }
    }
}
