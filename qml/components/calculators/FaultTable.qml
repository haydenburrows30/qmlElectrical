import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.platform as Platform

import FaultCurrentModel 1.0

Rectangle {
    // anchors.fill: parent
    // color: "white"

    property FaultCurrentModel calculator: FaultCurrentModel {}

    // Add a function to trigger PDF saving
    function saveToPdf() {
        fileDialog.open()
    }

    // Add a notification message
    function showNotification(message, isError = false) {
        notification.color = isError ? "#ffcccc" : "#ccffcc"
        notificationText.text = message
        notification.visible = true
        notificationTimer.restart()
    }

    // Connect to the PDF saved signal
    Connections {
        target: calculator
        function onPdfSaved(success, message) {
            if (success) {
                showNotification("PDF saved successfully at: " + message)
            } else {
                showNotification("Error saving PDF: " + message, true)
            }
        }
    }

    // Add file dialog for saving PDF
    Platform.FileDialog {
        id: fileDialog
        title: "Save as PDF"
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["PDF files (*.pdf)"]
        
        onAccepted: {
            // Get the file URL from the dialog
            const fileUrl = fileDialog.file
            
            // Log the original URL for debugging
            console.log("Original file URL:", fileUrl)
            
            // Convert the URL to a proper file path
            let filePath
            if (fileUrl.toString().startsWith("file:///")) {
                // Handle the file:/// protocol properly
                filePath = fileUrl.toString().replace(/^file:\/\/\//, "/")
            } else {
                filePath = fileUrl.toString()
            }
            
            console.log("Processing file path:", filePath)
            
            // Show notification with the path we're trying to use
            showNotification("Attempting to save to: " + filePath, false)
            
            // Send to the Python model
            calculator.exportToPdf(filePath)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Add a toolbar with save button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#f8f8f8"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                
                Button {
                    text: "Save to PDF"
                    onClicked: saveToPdf()
                    Layout.preferredHeight: 30
                }
                
                Item { Layout.fillWidth: true } // Spacer
            }
        }

        // Add notification area
        Rectangle {
            id: notification
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#ccffcc"
            visible: false
            
            Text {
                id: notificationText
                anchors.centerIn: parent
                font.pixelSize: 14
            }
            
            Timer {
                id: notificationTimer
                interval: 5000
                onTriggered: notification.visible = false
            }
        }

        // Add site information section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 160  // Increase height to fit new row
            color: "#fcfcfc"
            border.width: 1
            border.color: "#e0e0e0"

            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: 4
                rowSpacing: 10
                columnSpacing: 15

                // Site Name Relay 1
                Label {
                    text: "Site Name Relay 1:"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignRight
                }
                TextField {
                    id: siteNameRelay1
                    placeholderText: "Enter site name"
                    Layout.fillWidth: true
                    text: calculator.site_name_relay1
                    onTextChanged: calculator.site_name_relay1 = text
                }

                // Site Name Relay 2
                Label {
                    text: "Site Name Relay 2:"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignRight
                }
                TextField {
                    id: siteNameRelay2
                    placeholderText: "Enter site name"
                    Layout.fillWidth: true
                    text: calculator.site_name_relay2
                    onTextChanged: calculator.site_name_relay2 = text
                }

                // Serial Number Relay 1
                Label {
                    text: "Serial Number Relay 1:"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignRight
                }
                TextField {
                    id: serialNumberRelay1
                    placeholderText: "Enter serial number"
                    Layout.fillWidth: true
                    text: calculator.serial_number_relay1
                    onTextChanged: calculator.serial_number_relay1 = text
                }

                // Serial Number Relay 2
                Label {
                    text: "Serial Number Relay 2:"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignRight
                }
                TextField {
                    id: serialNumberRelay2
                    placeholderText: "Enter serial number"
                    Layout.fillWidth: true
                    text: calculator.serial_number_relay2
                    onTextChanged: calculator.serial_number_relay2 = text
                }

                // Loop Resistance
                Label {
                    text: "Loop Resistance:"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignRight
                }
                TextField {
                    id: loopResistance
                    placeholderText: "Enter loop resistance"
                    Layout.fillWidth: true
                    text: calculator.loop_resistance
                    onTextChanged: calculator.loop_resistance = text
                }
                
                // Padding Resistance (calculated)
                Label {
                    text: "Padding Resistance:"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignRight
                }
                Label {
                    text: calculator.padding_resistance
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    color: calculator.padding_resistance === "Error" ? "red" : "black"
                    background: Rectangle {
                        color: "#f0f0f0"
                        border.width: 1
                        border.color: "#d0d0d0"
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    padding: 8
                }
                
                // Standard Padding Resistance
                Label {
                    text: "Standard Padding:"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignRight
                }
                Label {
                    text: calculator.standard_padding_resistance + " Ω"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.columnSpan: 3  // Span all remaining columns for long text
                    color: calculator.standard_padding_resistance === "Error" ? "red" : "blue"
                    background: Rectangle {
                        color: "#e8f0ff"  // Light blue background
                        border.width: 1
                        border.color: "#a0c0ff"  // Blue border
                        radius: 3
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    padding: 8
                    wrapMode: Text.WordWrap  // Allow text wrapping for long combinations
                }
            }
        }

        TableView {
            id: tableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnSpacing: 0
            rowSpacing: 0
            clip: true
            topMargin: columnHeaderHeight
            leftMargin: rowHeaderWidth

            property real rowHeaderWidth: 80
            property real columnHeaderHeight: 40
            
            // Add explicit property bindings for row and column counts
            property int rows: calculator ? calculator.rowCount() : 0
            property int columns: calculator ? calculator.columnCount() : 0

            model: calculator

            rowHeightProvider: function() { return 40 }
            columnWidthProvider: function() { return 120 }

            // Update the corner rectangle to include "Fault Type" text
            Rectangle {
                id: cornerRect
                width: tableView.rowHeaderWidth
                height: tableView.columnHeaderHeight
                x: tableView.contentX
                y: tableView.contentY
                z: 3
                color: "#e0e0e0"
                border.width: 1
                border.color: "#d0d0d0"
                
                // Add text element to display "Fault Type"
                Text {
                    anchors.centerIn: parent
                    text: "Fault Type"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Row {
                id: columnHeader
                y: tableView.contentY
                z: 2
                x: tableView.rowHeaderWidth + tableView.contentX // Fix alignment

                Repeater {
                    model: tableView.columns
                    delegate: Rectangle {
                        width: tableView.columnWidthProvider(modelData)
                        height: tableView.columnHeaderHeight
                        color: "#f0f0f0"
                        border.width: 1
                        border.color: "#d0d0d0"

                        Text {
                            anchors.centerIn: parent
                            text: calculator.headerData(modelData, Qt.Horizontal)
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Column {
                id: rowHeader
                x: tableView.contentX
                z: 2
                y: tableView.columnHeaderHeight + tableView.contentY // Fix alignment

                Repeater {
                    model: tableView.rows
                    delegate: Rectangle {
                        width: tableView.rowHeaderWidth
                        height: tableView.rowHeightProvider(modelData)
                        color: "#f0f0f0"
                        border.width: 1
                        border.color: "#d0d0d0"

                        Text {
                            anchors.centerIn: parent
                            text: calculator.headerData(modelData, Qt.Vertical)
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // Replace delegateChooser with a standard delegate that handles both types
            delegate: Item {
                id: cellItem
                implicitWidth: 120
                implicitHeight: 40
                
                // Better column detection using model.column directly
                property bool isTextCell: {
                    // Use the column property if available, otherwise calculate it
                    if (model.column !== undefined) {
                        return model.column === 6;
                    } else {
                        // Fallback calculation - rows should be from model or tableView
                        let rows = tableView.rows > 0 ? tableView.rows : 6;
                        let col = Math.floor(model.index / rows); // using integer division
                        return col === 6;
                    }
                }
                
                // Create loader to load appropriate component
                Loader {
                    anchors.fill: parent
                    sourceComponent: isTextCell ? textComponent : numberComponent
                }
                
                // Component for editable number cells
                Component {
                    id: numberComponent
                    
                    TextField {
                        anchors.fill: parent
                        text: model.display
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        background: Rectangle {
                            border.width: 1
                            border.color: "#d0d0d0"
                        }
                        onEditingFinished: model.edit = text
                    }
                }
                
                // Component for non-editable text cells
                Component {
                    id: textComponent
                    
                    Rectangle {
                        anchors.fill: parent
                        border.width: 1
                        border.color: "#d0d0d0"
                        color: "#f5f5f5"  // Slightly different background to indicate read-only
                        
                        Text {
                            anchors.centerIn: parent
                            text: model.display
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // Add horizontal scrolling properties to ensure all columns are visible
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            // Make sure the model is initialized and the view is updated
            Component.onCompleted: {
                if (calculator) {
                    tableView.forceLayout()
                }
            }
        }
    }
}
