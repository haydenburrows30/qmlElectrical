import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"
import "../../components/charts"
import "../../components/monitors"
import "../voltage_drop/"

import VDrop 1.0

Page {
    id: root
    padding: 0

    property VoltageDropCalculator calculator: VoltageDropCalculator {
        id: voltageDrop
        
        Component.onCompleted: {
            // Initialize from saved settings
            if (typeof appConfig !== 'undefined') {
                // Get the default voltage from settings
                var defaultVoltage = appConfig.get_setting("default_voltage", "415V");
                setSelectedVoltage(defaultVoltage);
                
                // Get ADMD setting, but only apply it if voltage is 415V
                var admdEnabled = appConfig.get_setting("admd_enabled", false);
                if (selectedVoltage === "415V" && admdEnabled) {
                    setADMDEnabled(admdEnabled);
                }
            }
        }
    }

    // Use a safer property binding that prevents undefined values
    property real currentVoltageDropValue: {
        var value = voltageDrop.voltageDrop;
        return (value === undefined || value === null || isNaN(value)) ? 0.0 : value;
    }

    // Helper function to sanitize values
    function safeValue(value, defaultValue = 0) {
        return (value === undefined || value === null || isNaN(value)) ? 
            defaultValue : value;
    }

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<b>Overview</b><br> This tool is used to calculate the voltage drop in a cable system. The tool calculates the voltage drop based on the cable size, length, current, and other factors. The tool also provides a comparison of different cable sizes and their voltage drop values. <br> " +
            "<br> <b>Results</b><br> The tool displays the voltage drop, current, and other results of the calculation. You can save the results and view the details of the calculation."
        widthFactor: 0.3
        heightFactor: 0.3
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            id: flickableMain
            contentWidth: parent.width
            contentHeight: mainLayout.height + 20
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                width: flickableMain.width - 20

                // Header with title and help button
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5

                    Label {
                        text: "Voltage Drop Orion"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                RowLayout {
                    ColumnLayout {
                        WaveCard {
                            title: "Cable Selection"
                            Layout.minimumHeight: 540
                            Layout.minimumWidth: 420

                            CableSelectionSettings {
                                id: cableSettings
                                anchors.fill: parent

                                onResetCompleted: {
                                    root.currentVoltageDropValue = voltageDrop.voltageDrop || 0
                                    resultsPanel.combinedRatingInfo = voltageDrop.combinedRatingInfo || "N/A"
                                    resultsPanel.totalLoad = voltageDrop.totalKva || 0.0
                                    resultsPanel.current = voltageDrop.current || 0.0
                                }
                            }
                        }
                        
                        WaveCard {
                            title: "Results"
                            Layout.minimumHeight: 370
                            Layout.minimumWidth: 420

                            ResultsPanel {
                                id: resultsPanel
                                anchors.fill: parent
                                darkMode: window.modeToggled
                                voltageDropValue: root.currentVoltageDropValue
                                selectedVoltage: voltageDrop.selectedVoltage
                                diversityFactor: voltageDrop.diversityFactor
                                combinedRatingInfo: voltageDrop.combinedRatingInfo || "N/A"
                                totalLoad: voltageDrop.totalKva || 0.0
                                current: voltageDrop.current || 0.0
                                
                                onSaveResultsClicked: {
                                    resultsManager.save_calculation({
                                        "voltage_system": cableSettings.voltageSelect.currentText,
                                        "kva_per_house": safeValue(parseFloat(cableSettings.kvaPerHouseInput.text)),
                                        "num_houses": safeValue(parseInt(cableSettings.numberOfHousesInput.text), 1),
                                        "diversity_factor": safeValue(voltageDrop.diversityFactor, 1),
                                        "total_kva": safeValue(voltageDrop.totalKva),
                                        "current": safeValue(voltageDrop.current),
                                        "cable_size": cableSettings.cableSelect.currentText || "Unknown",
                                        "conductor": cableSettings.conductorSelect.currentText || "Unknown",
                                        "core_type": cableSettings.coreTypeSelect.currentText || "Unknown",
                                        "length": safeValue(parseFloat(cableSettings.lengthInput.text)),
                                        "voltage_drop": safeValue(root.currentVoltageDropValue),
                                        "drop_percent": safeValue(resultsPanel.dropPercentage),
                                        "admd_enabled": !!cableSettings.admdCheckBox.checked
                                    });
                                }
                                
                                onViewDetailsClicked: {
                                    detailsPopup.voltageSystem = voltageDrop.selectedVoltage
                                    detailsPopup.admdEnabled = voltageDrop.admdEnabled
                                    detailsPopup.kvaPerHouse = voltageDrop.totalKva / voltageDrop.numberOfHouses
                                    detailsPopup.numHouses = voltageDrop.numberOfHouses
                                    detailsPopup.diversityFactor = voltageDrop.diversityFactor
                                    detailsPopup.totalKva = voltageDrop.totalKva
                                    detailsPopup.current = voltageDrop.current
                                    detailsPopup.cableSize = cableSettings.cableSelect.currentText
                                    detailsPopup.conductorMaterial = voltageDrop.conductorMaterial
                                    detailsPopup.coreType = voltageDrop.coreType
                                    detailsPopup.length = cableSettings.lengthInput.text
                                    detailsPopup.installationMethod = cableSettings.installationMethodCombo.currentText
                                    detailsPopup.temperature = cableSettings.temperatureInput.text
                                    detailsPopup.groupingFactor = cableSettings.groupingFactorInput.text
                                    detailsPopup.combinedRatingInfo = voltageDrop.combinedRatingInfo
                                    detailsPopup.voltageDropValue = root.currentVoltageDropValue
                                    detailsPopup.dropPercentage = resultsPanel.dropPercentage
                                    detailsPopup.open()
                                }
                                
                                onViewChartClicked: {
                                    chartPopup.percentage = resultsPanel.dropPercentage
                                    chartPopup.cableSize = cableSettings.cableSelect.currentText
                                    chartPopup.currentValue = voltageDrop.current
                                    chartPopup.prepareChart()
                                    chartPopup.open()
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        WaveCard {
                            title: "Cable Size Comparison"
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ComparisonTable {
                                id: comparisonTable
                                anchors.fill: parent
                                darkMode: window.modeToggled
                                tableModel: voltageDrop.tableModel
                                
                                onExportRequest: function(format) {
                                    if (format === "csv") {
                                        voltageDrop.exportTableData()
                                    } else if (format === "pdf") {
                                        voltageDrop.exportTableToPDF()
                                    } else if (format === "menu") {
                                        exportFormatMenu.popup()
                                    }
                                }
                            }
                        }
                        
                        SavedResults {
                            Layout.fillWidth: true
                            Layout.minimumHeight: 300
                        }
                    }
                }
            }
        }
    }

    ChartPopup {
        id: chartPopup
    }
    
    MessagePopup {
        id: messagePopup
    }
    
    // Inline menu component rather than using a separate file
    Menu {
        id: exportFormatMenu
        title: "Export Format"
        
        MenuItem {
            text: "Export as CSV"
            onTriggered: voltageDrop.exportTableData()
        }

        MenuItem {
            text: "Export as PDF"
            onTriggered: voltageDrop.exportTableToPDF()
        }
    }

    Connections {
        target: voltageDrop

        function onVoltageDropCalculated(value) {
            // Add validation to prevent assigning undefined values
            if (value === undefined || value === null || isNaN(value)) {
                root.currentVoltageDropValue = 0.0;
                console.warn("Received invalid voltage drop value:", value);
            } else {
                root.currentVoltageDropValue = value;
            }
        }

        function onTableExportStatusChanged(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }

        function onTablePdfExportStatusChanged(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
        
        function onPdfExportStatusChanged(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
        
        function onSaveStatusChanged(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }

    VoltageDropDetails {
        id: detailsPopup
        anchors.centerIn: Overlay.overlay
        
        onCloseRequested: detailsPopup.close()

        onSaveToPdfRequested: {
            
            voltageDrop.exportDetailsToPDF(null, {
                "voltage_system": detailsPopup.voltageSystem || "Unknown",
                "admd_enabled": !!detailsPopup.admdEnabled,
                "kva_per_house": safeValue(detailsPopup.kvaPerHouse),
                "num_houses": safeValue(detailsPopup.numHouses, 1),
                "diversity_factor": safeValue(detailsPopup.diversityFactor, 1),
                "total_kva": safeValue(detailsPopup.totalKva),
                "current": safeValue(detailsPopup.current),
                "cable_size": detailsPopup.cableSize || "Unknown",
                "conductor_material": detailsPopup.conductorMaterial || "Unknown",
                "core_type": detailsPopup.coreType || "Unknown",
                "length": safeValue(parseFloat(detailsPopup.length)),
                "installation_method": detailsPopup.installationMethod || "Unknown",
                "temperature": safeValue(parseFloat(detailsPopup.temperature), 25),
                "grouping_factor": safeValue(parseFloat(detailsPopup.groupingFactor), 1.0),
                "combined_rating_info": detailsPopup.combinedRatingInfo || "N/A",
                "voltage_drop": safeValue(detailsPopup.voltageDropValue),
                "drop_percent": safeValue(detailsPopup.dropPercentage)
            })
        }
    }
}