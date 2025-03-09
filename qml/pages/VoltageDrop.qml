import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import components 1.0

Page {
    id: root
    padding: 0
    
    // Move model to top level and create explicit binding
    property real currentVoltageDropValue: voltageDrop.voltageDrop || 0
    
    // Add connections to ensure property updates when signal is emitted
    Connections {
        target: voltageDrop
        function onVoltageDropCalculated(value) {
            console.log("Voltage drop updated:", value)
            root.currentVoltageDropValue = value
        }
    }

    background: Rectangle {
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                ColumnLayout {
                    WaveCard {
                        title: "Cable Selection"
                        Layout.minimumHeight: 560
                        Layout.minimumWidth: 400
                        showInfo: false

                        CableSelectionSettings {
                            id: cableSettings
                            anchors.fill: parent
                            
                            onResetRequested: {
                                voltageSelect.currentIndex = 1  // 415V
                                conductorSelect.currentIndex = 1  // Al
                                coreTypeSelect.currentIndex = 1  // 3C+E
                                cableSelect.currentIndex = 13
                                currentInput.text = "0"
                                lengthInput.text = "0"
                                temperatureInput.text = "25"
                                groupingFactorInput.text = "1.0"
                                kvaPerHouseInput.text = "7"
                                numberOfHousesInput.text = "1"
                                admdCheckBox.checked = false
                                installationMethodCombo.currentIndex = 5  // "D1 - Underground direct buried"

                                // Reset results table and calculations
                                totalLoadText.text = "0.0"
                                
                                // Reset model state
                                voltageDrop.reset()
                                
                                // Force property reevaluation
                                root.currentVoltageDropValue = voltageDrop.voltageDrop || 0

                                // Make sure the UI updates by accessing the properties
                                console.log("After reset - voltage drop:", voltageDrop.voltageDrop)
                                console.log("After reset - current:", voltageDrop.current)
                                console.log("After reset - fuse size:", voltageDrop.networkFuseSize)
                                console.log("After reset - combined rating:", voltageDrop.combinedRatingInfo)
                                
                                // Explicitly update the fuse size display
                                networkFuseSizeText.text = voltageDrop.combinedRatingInfo
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Results"
                        Layout.minimumHeight: 330
                        Layout.minimumWidth:400
                        showInfo: false

                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            rowSpacing: 18

                            Label { text: "Voltage Drop: " }

                            Label {
                                id: dropValue
                                text: root.currentVoltageDropValue.toFixed(2) + " V"
                                font.weight: Font.Medium
                            }

                            Label { text: "Percentage Drop: " }

                            Label {
                                id: dropPercent
                                property real percentage: root.currentVoltageDropValue / (parseFloat(voltageDrop.selectedVoltage.slice(0, -1)) || 1) * 100
                                text: percentage.toFixed(2) + "%"
                                color: percentage > 5 ? "red" : "green"
                            }

                            Label { text: "Diversity Factor Applied: " }

                            Label {
                                text:  voltageDrop.diversityFactor.toFixed(2)
                            }

                            // Update Network Fuse Size display to show combined information
                            Label { text: "Network Fuse / Rating:" }
                            Text {
                                id: networkFuseSizeText
                                text: voltageDrop.combinedRatingInfo || "N/A"
                                color: text !== "N/A" && text !== "Not specified" && text !== "Error" ? 
                                       "blue" : (text === "Error" ? "red" : toolBar.toggle ? "#ffffff" : "#000000")
                                font.bold: text !== "N/A" && text !== "Not specified" && text !== "Error"
                                Layout.fillWidth: true
                                
                                Connections {
                                    target: voltageDrop
                                    function onCombinedRatingChanged(value) {
                                        networkFuseSizeText.text = value
                                    }
                                }
                            }

                            Label { text: "Total Load (kVA):" }
                            Text {
                                id: totalLoadText
                                text: "10.0"
                                font.bold: true
                                Layout.fillWidth: true
                                color: toolBar.toggle ? "#ffffff" : "#000000"

                                Connections {
                                    target: voltageDrop
                                    function onTotalLoadChanged(value) {
                                        totalLoadText.text = value.toFixed(1)
                                    }
                                }
                            }

                            Label { text: "Current (A):" }
                            Text {
                                id: currentInput
                                text: Number(voltageDrop.current).toFixed(1)
                                font.bold: true
                                color: toolBar.toggle ? "#ffffff" : "#000000"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                
                                // Add connection to update when current changes
                                Connections {
                                    target: voltageDrop
                                    function onCurrentChanged(value) {
                                        currentInput.text = value.toFixed(1)
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4

                                Rectangle {
                                    width: parent.width * Math.min((root.currentVoltageDropValue / voltageDrop.selectedVoltage.slice(0, -1) * 100) / 10, 1)
                                    height: parent.height
                                    radius: 4
                                    color: (root.currentVoltageDropValue / voltageDrop.selectedVoltage.slice(0, -1) * 100) > 5 ? "red" : "green"
                                    Behavior on width { NumberAnimation { duration: 200 } }
                                }
                            }

                            RowLayout {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                spacing: 10

                                Button {
                                    text: "Save Results"
                                    icon.name: "Save"
                                    enabled: root.currentVoltageDropValue > 0
                                    onClicked: {
                                        // Fix the references to use cableSettings component properties instead
                                        resultsManager.save_calculation({
                                            "voltage_system": cableSettings.voltageSelect.currentText,
                                            "kva_per_house": parseFloat(cableSettings.kvaPerHouseInput.text),
                                            "num_houses": parseInt(cableSettings.numberOfHousesInput.text),
                                            "diversity_factor": voltageDrop.diversityFactor,
                                            "total_kva": parseFloat(totalLoadText.text),
                                            "current": parseFloat(currentInput.text),
                                            "cable_size": cableSettings.cableSelect.currentText,
                                            "conductor": cableSettings.conductorSelect.currentText,
                                            "core_type": cableSettings.coreTypeSelect.currentText,
                                            "length": parseFloat(cableSettings.lengthInput.text),
                                            "voltage_drop": root.currentVoltageDropValue,
                                            "drop_percent": dropPercent.percentage,
                                            "admd_enabled": cableSettings.admdCheckBox.checked
                                        });
                                    }
                                }

                                Button {
                                    text: "Show Details"
                                    icon.name: "Info"
                                    enabled: root.currentVoltageDropValue > 0
                                    onClicked: {
                                        // Pass all required data to the details popup
                                        detailsPopup.voltageSystem = voltageDrop.selectedVoltage
                                        detailsPopup.admdEnabled = voltageDrop.admdEnabled
                                        detailsPopup.kvaPerHouse = voltageDrop.totalKva / voltageDrop.numberOfHouses
                                        detailsPopup.numHouses = voltageDrop.numberOfHouses
                                        detailsPopup.diversityFactor = voltageDrop.diversityFactor
                                        detailsPopup.totalKva = voltageDrop.totalKva
                                        detailsPopup.current = parseFloat(currentInput.text)
                                        detailsPopup.cableSize = cableSettings.cableSelect.currentText
                                        detailsPopup.conductorMaterial = voltageDrop.conductorMaterial
                                        detailsPopup.coreType = voltageDrop.coreType
                                        detailsPopup.length = cableSettings.lengthInput.text
                                        detailsPopup.installationMethod = cableSettings.installationMethodCombo.currentText
                                        detailsPopup.temperature = cableSettings.temperatureInput.text
                                        detailsPopup.groupingFactor = cableSettings.groupingFactorInput.text
                                        detailsPopup.combinedRatingInfo = voltageDrop.combinedRatingInfo
                                        detailsPopup.voltageDropValue = root.currentVoltageDropValue
                                        detailsPopup.dropPercentage = dropPercent.percentage
                                        detailsPopup.open()
                                    }
                                }
                
                                Button {
                                    text: "View Chart"
                                    icon.name: "Chart"
                                    enabled: root.currentVoltageDropValue > 0
                                    onClicked: {
                                        chartPopup.open()
                                    }
                                }

                                Connections {
                                    target: voltageDrop
                                    function onSaveStatusChanged(success, message) {
                                        if (success) {
                                            saveSuccess.messageText = message
                                            saveSuccess.open()
                                        } else {
                                            saveError.messageText = message
                                            saveError.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    WaveCard {
                        title: "Cable Size Comparison"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        showInfo: false

                        ColumnLayout {
                            anchors.fill: parent

                            // Header row that syncs with table
                            Item {
                                Layout.fillWidth: true
                                height: 40
                                clip: true

                                Rectangle {
                                    width: tableView.width
                                    height: parent.height
                                    color: toolBar.toggle ? "#424242" : "#e0e0e0"
                                    x: -tableView.contentX  // Sync with table horizontal scroll
                                    
                                    Row {
                                        anchors.fill: parent
                                        Repeater {
                                            model: [
                                                "Size (mm²)", 
                                                "Material", 
                                                "Cores", 
                                                "mV/A/m", 
                                                "Rating (A)", 
                                                "V-Drop (V)", 
                                                "Drop %", 
                                                "Status"
                                            ]
                                            
                                            Rectangle {
                                                width: getColumnWidth(index)
                                                height: parent.height
                                                color: "transparent"
                                                
                                                Label {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    text: modelData
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    elide: Text.ElideRight
                                                    color: toolBar.toggle ? "#ffffff" : "#000000"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Table content
                            ScrollView {
                                id: tableScrollView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                clip: true

                                TableView {
                                    id: tableView
                                    anchors.fill: parent
                                    model: voltageDrop.tableModel
                                    boundsMovement: Flickable.StopAtBounds

                                    // Fix table interaction - replace existing MouseArea implementation
                                    MouseArea {
                                        z: -1  // Place behind TableView so delegates can still receive events
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        
                                        onWheel: function(wheelEvent) {
                                            if (wheelEvent.modifiers & Qt.ShiftModifier) {
                                                // Shift+wheel for horizontal scrolling
                                                tableView.contentX -= wheelEvent.angleDelta.y
                                                wheelEvent.accepted = true
                                            } else {
                                                // Regular wheel for vertical scrolling
                                                tableView.contentY -= wheelEvent.angleDelta.y
                                                wheelEvent.accepted = true
                                            }
                                        }

                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.RightButton) {
                                                tableContextMenu.popup()
                                            }
                                        }
                                    }

                                    // Add missing context menu for the table
                                    Menu {
                                        id: tableContextMenu
                                        
                                        MenuItem {
                                            text: "Export as CSV"
                                            onTriggered: tableExportDialog.open()
                                        }
                                        
                                        MenuItem {
                                            text: "Export as PDF"
                                            onTriggered: tablePdfExportDialog.open()
                                        }
                                        
                                        MenuSeparator {}
                                        
                                        MenuItem {
                                            text: "Reset Scroll Position"
                                            onTriggered: {
                                                tableView.contentX = 0
                                                tableView.contentY = 0
                                            }
                                        }
                                    }

                                    // Standard delegate implementation for table cells
                                    delegate: Rectangle {
                                        implicitWidth: getColumnWidth(column)
                                        implicitHeight: 40
                                        color: {
                                            if (column === 7) {  // Status column
                                                switch(model.display) {
                                                    case "SEVERE": return "#ffebee"  // Red background
                                                    case "WARNING": return "#fff3e0"  // Orange background
                                                    case "SUBMAIN": return "#e3f2fd"  // Blue background
                                                    case "OK": return "#e8f5e9"      // Green background
                                                    default: return "transparent"
                                                }
                                            }
                                            return row % 2 ? (toolBar.toggle ? "#2d2d2d" : "#f5f5f5") 
                                                        : (toolBar.toggle ? "#1d1d1d" : "#ffffff")
                                        }

                                        Text {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            text: model.display
                                            color: {
                                                if (column === 7) {  // Status column
                                                    switch(model.display) {
                                                        case "SEVERE": return "#c62828"  // Dark red
                                                        case "WARNING": return "#ef6c00"  // Dark orange
                                                        case "SUBMAIN": return "#1565c0"  // Dark blue
                                                        case "OK": return "#2e7d32"      // Dark green
                                                        default: return toolBar.toggle ? "#ffffff" : "#000000"
                                                    }
                                                }
                                                return toolBar.toggle ? "#ffffff" : "#000000"
                                            }
                                            font.bold: column === 7  // Status column
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }

                            // Add button to save table data
                            Button {
                                text: "Export Table"
                                icon.name: "document-save"
                                // Fix the line that's causing the error by using a safer approach to check for table data
                                enabled: voltageDrop.tableModel && voltageDrop.tableModel.rowCount() > 0
                                Layout.alignment: Qt.AlignRight
                                Layout.margins: 5
                                
                                // Replace with menu for export options
                                onClicked: tableExportMenu.popup()
                                
                                ToolTip.visible: hovered
                                ToolTip.text: "Export cable comparison data"
                                
                                // Add menu for export options
                                Menu {
                                    id: tableExportMenu
                                    title: "Export Format"
                                    
                                    MenuItem {
                                        text: "Export as CSV"
                                        onTriggered: tableExportDialog.open()
                                    }
                                    
                                    MenuItem {
                                        text: "Export as PDF"
                                        onTriggered: tablePdfExportDialog.open()
                                    }
                                }
                            }
                        }
                    }
                    // Update SavedResults card with resultsManager property
                    SavedResults {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 300
                    }
                }
            }
        }
    }

    // Popup containing the VoltageDropChart component
    Popup {
        id: chartPopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 700
        height: 500
        
        // Call this when the popup is about to show
        onAboutToShow: {
            chartComponent.percentage = dropPercent.percentage
            chartComponent.cableSize = cableSettings.cableSelect.currentText
            chartComponent.currentValue = parseFloat(currentInput.text) 
            chartComponent.updateChart()
        }
        
        // Use the new component for the chart
        VoltageDropChart {
            id: chartComponent
            anchors.fill: parent
            
            // Connect signals
            onCloseRequested: chartPopup.close()
            onSaveRequested: chartSaveDialog.open()
        }
    }
    
    // Add ComboBox for chart resolution (hidden)
    ComboBox {
        id: resolutionComboBox
        model: ["1x", "2x", "4x"]
        property var scaleValues: [1.0, 2.0, 4.0]
        property real scaleFactor: scaleValues[currentIndex]
        visible: false
    }
    
    // Add FileDialog for saving chart
    FileDialog {
        id: chartSaveDialog
        title: "Save Chart"
        nameFilters: ["PNG files (*.png)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        defaultSuffix: "png"
        currentFolder: Qt.platform.os === "windows" ? "file:///C:" : "file:///home"
        
        // Generate default filename with timestamp
        currentFile: {
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            return "voltage_drop_chart_" + timestamp + ".png"
        }
        
        onAccepted: {
            voltageDrop.saveChart(selectedFile, resolutionComboBox.scaleFactor)
        }
    }
    
    // Add FileDialog for exporting table data
    FileDialog {
        id: tableExportDialog
        title: "Export Table Data"
        nameFilters: ["CSV files (*.csv)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        defaultSuffix: "csv"
        currentFolder: Qt.platform.os === "windows" ? "file:///C:" : "file:///home"
        
        // Generate default filename with timestamp
        currentFile: {
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            return "cable_comparison_" + timestamp + ".csv"
        }
        
        onAccepted: {
            voltageDrop.exportTableData(selectedFile)
        }
    }

    // Add FileDialog for exporting table to PDF
    FileDialog {
        id: tablePdfExportDialog
        title: "Export Table as PDF"
        nameFilters: ["PDF files (*.pdf)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        defaultSuffix: "pdf"
        currentFolder: Qt.platform.os === "windows" ? "file:///C:" : "file:///home"
        
        // Generate default filename with timestamp
        currentFile: {
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            return "cable_comparison_" + timestamp + ".pdf"
        }
        
        onAccepted: {
            voltageDrop.exportTableToPDF(selectedFile)
        }
    }
    
    // Add connections for chart and export handling
    Connections {
        target: voltageDrop
        function onGrabRequested(filepath, scale) {
            console.log("Grabbing image to:", filepath, "with scale:", scale)
            chartComponent.grabChartImage(function(result) {
                if (result) {
                    var saved = result.saveToFile(filepath)
                    if (saved) {
                        saveSuccess.messageText = "Chart saved successfully"
                        saveSuccess.open()
                    } else {
                        saveError.messageText = "Failed to save chart"
                        saveError.open()
                    }
                } else {
                    saveError.messageText = "Failed to grab chart image"
                    saveError.open()
                }
            }, scale)
        }
        
        function onTableExportStatusChanged(success, message) {
            if (success) {
                saveSuccess.messageText = message
                saveSuccess.open()
            } else {
                saveError.messageText = message
                saveError.open()
            }
        }

        function onTablePdfExportStatusChanged(success, message) {
            if (success) {
                saveSuccess.messageText = message
                saveSuccess.open()
            } else {
                saveError.messageText = message
                saveError.open()
            }
        }
    }

    // Add general success and error message popups
    Popup {
        id: saveSuccess
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 100
        
        property string messageText: ""

        contentItem: ColumnLayout {
            Label {
                text: saveSuccess.messageText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: saveSuccess.close()
            }
        }
    }
    
    Popup {
        id: saveError
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 100
        
        property string messageText: ""

        contentItem: ColumnLayout {
            Label {
                text: saveError.messageText
                wrapMode: Text.WordWrap
                color: "red"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: saveError.close()
            }
        }
    }

    // Add connections for PDF export handling
    Connections {
        target: voltageDrop
        
        // ...existing connection handlers...
        
        function onPdfExportStatusChanged(success, message) {
            // Forward the PDF export status to the popup
            detailsPopup.pdfSaveResult(success, message)
        }
    }

    function getColumnWidth(column) {
        switch(column) {
            case 0: return 100  // Size
            case 1: return 100  // Material
            case 2: return 100  // Cores
            case 3: return 100  // mV/A/m
            case 4: return 120  // Rating
            case 5: return 120  // V-Drop
            case 6: return 100  // Drop %
            case 7: return 100  // Status
            default: return 100
        }
    }

    // Replace the detailed results popup with the new component
    VoltageDropDetails {
        id: detailsPopup
        anchors.centerIn: Overlay.overlay
        
        onCloseRequested: detailsPopup.close()
        
        // Add handler for PDF save request
        onSaveToPdfRequested: function(filepath) {
            // Create details object with all the data needed for the PDF
            const details = {
                "voltage_system": voltageSystem,
                "admd_enabled": admdEnabled,
                "kva_per_house": kvaPerHouse,
                "num_houses": numHouses,
                "diversity_factor": diversityFactor,
                "total_kva": totalKva,
                "current": current,
                "cable_size": cableSize,
                "conductor_material": conductorMaterial,
                "core_type": coreType,
                "length": length,
                "installation_method": installationMethod,
                "temperature": temperature,
                "grouping_factor": groupingFactor,
                "combined_rating_info": combinedRatingInfo,
                "voltage_drop": voltageDropValue,
                "drop_percent": dropPercentage
            }
            
            // Call the Python method to generate PDF
            voltageDrop.exportDetailsToPDF(filepath, details)
        }
        
        // Display result messages
        onPdfSaveResult: function(success, message) {
            if (success) {
                pdfSaveSuccess.messageText = message
                pdfSaveSuccess.open()
            } else {
                pdfSaveError.messageText = message
                pdfSaveError.open()
            }
        }
    }

    // Add message popups for PDF export
    Popup {
        id: pdfSaveSuccess
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 100
        
        property string messageText: ""

        contentItem: ColumnLayout {
            Label {
                text: pdfSaveSuccess.messageText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: pdfSaveSuccess.close()
            }
        }
    }
    
    Popup {
        id: pdfSaveError
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 100
        
        property string messageText: ""

        contentItem: ColumnLayout {
            Label {
                text: pdfSaveError.messageText
                wrapMode: Text.WordWrap
                color: "red"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: pdfSaveError.close()
            }
        }
    }
}