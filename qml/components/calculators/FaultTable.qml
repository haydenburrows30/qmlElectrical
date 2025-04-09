import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.platform as Platform

import "../"
import "../style"
import "../buttons"

import FaultCurrentModel 1.0

Item {

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
        
        // Initialize comparison data when the component loads
        Component.onCompleted: calculator.updateComparisons()
    }

    // Add file dialog for saving PDF
    Platform.FileDialog {
        id: fileDialog
        title: "Save as PDF"
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["PDF files (*.pdf)"]
        
        onAccepted: {
            const fileUrl = fileDialog.file
            console.log("Original file URL:", fileUrl)

            let filePath
            if (fileUrl.toString().startsWith("file:///")) {

                filePath = fileUrl.toString().replace(/^file:\/\/\//, "/")
            } else {
                filePath = fileUrl.toString()
            }
            
            console.log("Processing file path:", filePath)
            showNotification("Attempting to save to: " + filePath, false)
            calculator.exportToPdf(filePath)
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 40
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                anchors.centerIn: parent
                width: 800
                
                // Save button
                RowLayout {
                    Layout.minimumHeight: 40
                    Layout.fillWidth: true
                    
                    Button {
                        text: "Save to PDF"
                        onClicked: saveToPdf()
                        Layout.preferredHeight: 30
                    }
                }

                // Add site information section
                RowLayout {
                    WaveCard {
                        id: siteInfoCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        Layout.alignment: Qt.AlignHCenter

                        title: "Site Information"

                        GridLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            columns: 2

                            // Site Name Relay 1
                            Label {
                                text: "Site Name Relay 1:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120  // Set minimum width to ensure alignment
                            }
                            TextFieldRound {
                                id: siteNameRelay1
                                placeholderText: "Enter site name"
                                Layout.fillWidth: true
                                text: calculator.site_name_relay1
                                onTextChanged: calculator.site_name_relay1 = text
                            }

                            // Site Name Relay 2
                            Label {
                                text: "Site Name Relay 2:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: siteNameRelay2
                                placeholderText: "Enter site name"
                                Layout.fillWidth: true
                                text: calculator.site_name_relay2
                                onTextChanged: calculator.site_name_relay2 = text
                            }

                            // Serial Number Relay 1
                            Label {
                                text: "Serial Number Relay 1:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: serialNumberRelay1
                                placeholderText: "Enter serial number"
                                Layout.fillWidth: true
                                text: calculator.serial_number_relay1
                                onTextChanged: calculator.serial_number_relay1 = text
                            }

                            // Serial Number Relay 2
                            Label {
                                text: "Serial Number Relay 2:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: serialNumberRelay2
                                placeholderText: "Enter serial number"
                                Layout.fillWidth: true
                                text: calculator.serial_number_relay2
                                onTextChanged: calculator.serial_number_relay2 = text
                            }
                        }
                    }
                    // Resistance Calc
                    WaveCard {
                        id: resistanceCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        Layout.alignment: Qt.AlignHCenter

                        title: "Resistance"

                        GridLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            columns: 2

                            // Loop Resistance
                            Label {
                                text: "Loop Resistance:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: loopResistance
                                placeholderText: "Enter loop resistance"
                                Layout.fillWidth: true
                                text: calculator.loop_resistance
                                onTextChanged: calculator.loop_resistance = text
                            }

                            // Padding Resistance (calculated)
                            Label {
                                text: "Padding Resistance:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldBlue {
                                text: calculator.padding_resistance
                                Layout.fillWidth: true
                                color: calculator.padding_resistance === "Error" ? "red" : "black"
                            }
                            
                            // Standard Padding Resistance
                            Label {
                                text: "Standard Padding:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldBlue {
                                text: calculator.standard_padding_resistance
                                Layout.fillWidth: true
                                color: calculator.standard_padding_resistance === "Error" ? "red" : "blue"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // Notification area
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

                // Tableview
                WaveCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    Layout.alignment: Qt.AlignHCenter
                    titleVisible: false

                    TableView {
                        id: tableView
                        anchors.fill: parent
                        columnSpacing: 0
                        rowSpacing: 0
                        clip: true
                        topMargin: columnHeaderHeight
                        leftMargin: rowHeaderWidth

                        property real rowHeaderWidth: 80
                        property real columnHeaderHeight: 60
                        
                        // Add explicit property bindings for row and column counts
                        property int rows: calculator ? calculator.rowCount() : 0
                        property int columns: calculator ? calculator.columnCount() : 0

                        model: calculator

                        rowHeightProvider: function() { return 40 }
                        columnWidthProvider: function() { return 110 }

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
                                        width: parent.width
                                        height: parent.height
                                        horizontalAlignment : Text.AlignHCenter
                                        verticalAlignment : Text.AlignVCenter
                                        text: calculator.headerData(modelData, Qt.Horizontal)
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
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
                            
                            // Get current cell value - bind to model.display to update when it changes
                            property string currentValue: model.display
                            
                            // Calculate if the cell is out of spec based on its column and value
                            property bool isOutOfSpec: {
                                try {
                                    let val = parseFloat(currentValue);
                                    let row = model.row !== undefined ? model.row : (model.index % tableView.rows);
                                    let col = model.column !== undefined ? model.column : Math.floor(model.index / tableView.rows);
                                    
                                    // For mA DC columns (1, 2, 4, 5)
                                    if (col === 1 || col === 2 || col === 4 || col === 5) {
                                        // Compare with reference value 11 mA, allow ±0.5 mA
                                        return (val !== 0) && (Math.abs(val - 11.0) > 0.5);
                                    }
                                    
                                    // For injection current columns (0, 3)
                                    if (col === 0 || col === 3) {
                                        // Get fault setting for this row
                                        let faultSetting = parseFloat(calculator.data(calculator.index(row, 6)));
                                        if (val === 0) return false; // Skip empty values
                                        
                                        // Check if current is outside 90-110% of fault setting
                                        let percentage = (val / faultSetting) * 100;
                                        return (percentage < 90 || percentage > 110);
                                    }
                                    
                                    return false;
                                } catch (e) {
                                    return false;
                                }
                            }
                            
                            // Determine if cell value is OK (within spec)
                            property bool isOk: {
                                try {
                                    let val = parseFloat(currentValue);
                                    if (val === 0) return false; // Don't highlight empty cells as OK
                                    return !isOutOfSpec && val !== 0;
                                } catch (e) {
                                    return false;
                                }
                            }
                            
                            // Add connection to update colors when comparison results change
                            Connections {
                                target: calculator
                                function onComparisonResultsChanged() {
                                    // Force property reevaluation
                                    cellItem.currentValue = Qt.binding(function() { return model.display; });
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
                                    
                                    // Update background immediately as text changes
                                    onTextChanged: {
                                        cellItem.currentValue = text;
                                    }
                                    
                                    background: Rectangle {
                                        id: cellBackground
                                        border.width: 1
                                        border.color: "#d0d0d0"
                                        color: {
                                            if (cellItem.isOutOfSpec) return "#ffe0e0";  // Red for out of spec
                                            else if (cellItem.isOk) return "#e0ffe0";    // Green for ok
                                            else return "white";                         // Default white
                                        }
                                    }
                                    
                                    onEditingFinished: {
                                        model.edit = text;
                                        // Force update of currentValue and color after editing
                                        cellItem.currentValue = text;
                                    }
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

                // Add mA DC comparison section
                WaveCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    Layout.alignment: Qt.AlignHCenter

                    title: "mA DC Value Comparison (Reference: 11 mA)"

                    GridLayout {
                        columns: 5
                        columnSpacing: 10
                        rowSpacing: 5

                        // Header row
                        Label {
                            text: "Fault Type"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                        }
                        Label {
                            text: "Test 1 Relay 1"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                            Layout.minimumWidth: 120
                        }
                        Label {
                            text: "Test 1 Relay 2"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                            Layout.minimumWidth: 120
                        }
                        Label {
                            text: "Test 2 Relay 1"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                            Layout.minimumWidth: 120
                        }
                        Label {
                            text: "Test 2 Relay 2"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                            Layout.minimumWidth: 120
                        }

                        // Generate mA DC comparison rows
                        Repeater {
                            model: 6 // Number of fault types
                            
                            delegate: RowLayout {
                                Layout.columnSpan: 5
                                Layout.fillWidth: true
                                
                                property int rowIndex: model.index
                                property string rowType: calculator.headerData(rowIndex, Qt.Vertical)
                                
                                // Get mA DC values
                                property string test1Relay1: calculator.data(calculator.index(rowIndex, 1))
                                property string test1Relay2: calculator.data(calculator.index(rowIndex, 2))
                                property string test2Relay1: calculator.data(calculator.index(rowIndex, 4))
                                property string test2Relay2: calculator.data(calculator.index(rowIndex, 5))
                                
                                // Get comparison results
                                property string result1R1: calculator.test1_relay1_ma_comparison[rowIndex]
                                property string result1R2: calculator.test1_relay2_ma_comparison[rowIndex]
                                property string result2R1: calculator.test2_relay1_ma_comparison[rowIndex]
                                property string result2R2: calculator.test2_relay2_ma_comparison[rowIndex]
                                
                                // Calculate background colors based on comparison results
                                property color color1R1: {
                                    if (result1R1.indexOf("OUT") >= 0) return "#ffe0e0"
                                    else if (result1R1.indexOf("OK") >= 0) return "#e0ffe0"
                                    else return "white"
                                }
                                
                                property color color1R2: {
                                    if (result1R2.indexOf("OUT") >= 0) return "#ffe0e0"
                                    else if (result1R2.indexOf("OK") >= 0) return "#e0ffe0"
                                    else return "white"
                                }
                                
                                property color color2R1: {
                                    if (result2R1.indexOf("OUT") >= 0) return "#ffe0e0"
                                    else if (result2R1.indexOf("OK") >= 0) return "#e0ffe0"
                                    else return "white"
                                }
                                
                                property color color2R2: {
                                    if (result2R2.indexOf("OUT") >= 0) return "#ffe0e0"
                                    else if (result2R2.indexOf("OK") >= 0) return "#e0ffe0"
                                    else return "white"
                                }
                                
                                Label {
                                    text: rowType
                                    Layout.preferredWidth: 60
                                    horizontalAlignment: Text.AlignCenter
                                    font.bold: true
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.preferredHeight: 25
                                    color: color1R1
                                    border.width: 1
                                    border.color: "#d0d0d0"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: result1R1
                                        font.bold: true
                                    }
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.preferredHeight: 25
                                    color: color1R2
                                    border.width: 1
                                    border.color: "#d0d0d0"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: result1R2
                                        font.bold: true
                                    }
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.preferredHeight: 25
                                    color: color2R1
                                    border.width: 1
                                    border.color: "#d0d0d0"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: result2R1
                                        font.bold: true
                                    }
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.preferredHeight: 25
                                    color: color2R2
                                    border.width: 1
                                    border.color: "#d0d0d0"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: result2R2
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }

                // Comparison section
                WaveCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    Layout.alignment: Qt.AlignHCenter

                    title: "Comparison Analysis"

                    GridLayout {
                        columns: 7
                        columnSpacing: 10
                        rowSpacing: 5

                        // Header row
                        Label {
                            text: "Fault Type"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                        }
                        // Label {
                        //     text: "Test 1 Inj Current"
                        //     Layout.alignment: Qt.AlignCenter
                        //     font.bold: true
                        //     Layout.minimumWidth: 120
                        // }
                        Label {
                            text: "Fault Settings"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                            Layout.minimumWidth: 100
                        }
                        Label {
                            text: "Test 1 %"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                            Layout.minimumWidth: 100
                        }
                        // Label {
                        //     text: "Test 2 Inj Current"
                        //     Layout.alignment: Qt.AlignCenter
                        //     font.bold: true
                        //     Layout.minimumWidth: 120
                        // }
                        // Label {
                        //     text: "Fault Settings"
                        //     Layout.alignment: Qt.AlignCenter
                        //     font.bold: true
                        //     Layout.minimumWidth: 100
                        // }
                        Label {
                            text: "Test 2 %"
                            Layout.alignment: Qt.AlignCenter
                            font.bold: true
                            Layout.minimumWidth: 100
                        }

                        // Generate comparison rows
                        Repeater {
                            model: 6 // Number of fault types
                            
                            delegate: RowLayout {
                                Layout.columnSpan: 5
                                Layout.fillWidth: true
                                
                                property int rowIndex: model.index
                                property string rowType: calculator.headerData(rowIndex, Qt.Vertical)
                                // property string test1Current: calculator.data(calculator.index(rowIndex, 0))
                                property string faultSetting: calculator.data(calculator.index(rowIndex, 6))
                                // property string test2Current: calculator.data(calculator.index(rowIndex, 3))
                                property string test1Result: calculator.test1_comparison[rowIndex]
                                property string test2Result: calculator.test2_comparison[rowIndex]
                                
                                // Calculate background colors based on comparison results
                                property color test1Color: {
                                    if (test1Result.indexOf("LOW") >= 0) return "#ffe0e0"
                                    else if (test1Result.indexOf("HIGH") >= 0) return "#ffe0e0"
                                    else if (test1Result.indexOf("OK") >= 0) return "#e0ffe0"
                                    else return "white"
                                }
                                
                                property color test2Color: {
                                    if (test2Result.indexOf("LOW") >= 0) return "#ffe0e0"
                                    else if (test2Result.indexOf("HIGH") >= 0) return "#ffe0e0"
                                    else if (test2Result.indexOf("OK") >= 0) return "#e0ffe0"
                                    else return "white"
                                }
                                
                                Label {
                                    text: rowType
                                    Layout.preferredWidth: 60
                                    horizontalAlignment: Text.AlignCenter
                                    font.bold: true
                                }
                                
                                // Label {
                                //     text: test1Current
                                //     Layout.preferredWidth: 120
                                //     horizontalAlignment: Text.AlignCenter
                                // }
                                
                                Label {
                                    text: faultSetting
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignCenter
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 25
                                    color: test1Color
                                    border.width: 1
                                    border.color: "#d0d0d0"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: test1Result
                                        font.bold: true
                                    }
                                }
                                
                                // Label {
                                //     text: test2Current
                                //     Layout.preferredWidth: 120
                                //     horizontalAlignment: Text.AlignCenter
                                // }
                                
                                // Label {
                                //     text: faultSetting
                                //     Layout.preferredWidth: 100
                                //     horizontalAlignment: Text.AlignCenter
                                // }
                                
                                Rectangle {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 25
                                    color: test2Color
                                    border.width: 1
                                    border.color: "#d0d0d0"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: test2Result
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
