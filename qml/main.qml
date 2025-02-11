import QtQuick 6.2
import QtQuick.Controls 6.2
import Qt.labs.qmlmodels 1.0
import QtQml 6.2
import QtQuick.Dialogs

import QtQuick.Controls.Universal

import Python 1.0
import VoltageDrop 1.0

Window {
    id: window
    
    minimumWidth: 600
    minimumHeight: 400
    height: 400
    visible: true

    PythonModel {
        id: pythonModel
    }

    VoltageDropModel {
        id: voltageDropModel
    }

    Button {
        id: addRowButton
        text: "Add Row"
        anchors {
            top: parent.top
            left: parent.left
            margins: 5
        }
         
        onClicked: {
            //if text field is in edit mode, close it
            tableView.closeEditor()
            pythonModel.appendRow([1, "2", "3", "4", "5"])
        }
    }

    Button {
        id: deleteLastRowButton
        text: "Delete Last Row"
        anchors {
            top: parent.top
            left: addRowButton.right
            margins: 5
        }
        onClicked: {
            if (pythonModel.rowCount() > 1) {
                pythonModel.removeRows(pythonModel.rowCount() - 1)
            }
        }
    }

    Button {
        id: clearAllRowsButton
        text: "Clear All Rows"
        anchors {
            top: parent.top
            left: deleteLastRowButton.right
            margins: 5
        }
        onClicked: {
            pythonModel.clearAllRows()
        }
    }

        Button {
        id: loadCSVButton
        text: "Load CSV"
        anchors {
            top: parent.top
            left: clearAllRowsButton.right
            margins: 5
        }
        onClicked: {
            fileDialog.open()
        }
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
                        implicitWidth: 100
                        implicitHeight: 50
                        model: pythonModel.getDropdownValues()
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

                            // Component.onCompleted: {
                            //     var modelData = TableView.view.model.data(TableView.view.index(row, column)).toString()
                            //     var dropdownValues = pythonModel.getDropdownValues()
                            //     var index = dropdownValues.indexOf(modelData)
                            //     display = index !== -1 ? index.toString() : modelData  // Initialize display using ComboBox index
                            // }

                            onTextChanged: {
                                if (text !== display) {
                                    TableView.view.model.setData(TableView.view.index(row, column), text)
                                    display = text  // Update the display property
                                }
                            }

                            // TableView.onCommit: {
                            //     display = text
                            //     focus = false  // Clear focus after committing changes
                            // }

                            // onEditingFinished: {
                            //     focus = false  // Clear focus after editing is finished
                            // }
                        }
                    }
                }
            }
        }
    }
}