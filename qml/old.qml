       // old buttons
       
        Frame {
            id: buttons
            width: parent.width

            RowLayout {

                Button {
                    id: addRowButton
                    text: "Add Row"

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

                    onClicked: {
                        if (pythonModel.rowCount() > 1) {
                            pythonModel.removeRows(pythonModel.rowCount() - 1)
                        }
                    }
                }

                Button {
                    id: clearAllRowsButton
                    text: "Clear All Rows"

                    onClicked: {
                        pythonModel.clearAllRows()
                    }
                }

                Button {
                    id: loadCSVButton
                    text: "Load CSV"

                    onClicked: fileDialog.open()
                }
            }
        }