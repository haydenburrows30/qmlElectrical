import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Dialogs
import Qt.labs.platform

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import NetworkCabinetCalculator 1.0

Item {
    id: cabinetCalculator

    property NetworkCabinetCalculator calculator: NetworkCabinetCalculator {
        id: networkCabinet
        
        onPdfExportStatusChanged: function(message) {
            statusPopup.message = message
            statusPopup.visible = true
        }
        
        onSaveLoadStatusChanged: function(message) {
            statusPopup.message = message
            statusPopup.visible = true
        }
    }
    
    property bool darkMode: window.modeToggled
    
    // File dialogs for operations
    FolderDialog {
        id: folderDialog
        title: "Select Folder to Save PDF"
        
        onAccepted: {
            // Use the selected folder directly
            calculator.exportToPdf(folderDialog.folder)
        }
    }
    
    FileDialog {
        id: saveConfigDialog
        title: "Save Configuration"
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON Files (*.json)", "All Files (*)"]
        
        onAccepted: {
            calculator.saveConfig(saveConfigDialog.file)
        }
    }
    
    FileDialog {
        id: loadConfigDialog
        title: "Load Configuration"
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON Files (*.json)", "All Files (*)"]
        
        onAccepted: {
            calculator.loadConfig(loadConfigDialog.file)
        }
    }
    
    // Status popup for messages
    Popup {
        id: statusPopup
        width: 400
        height: 100
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        
        property string message: ""
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            
            Label {
                text: statusPopup.message
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignRight
                onClicked: statusPopup.visible = false
            }
        }
    }
    
    // Help popup
    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>DC-M1 Network Cabinet Calculator</h3><br>" +
                   "This calculator helps you visualize and configure a DC-M1 electrical network cabinet.<br><br>" +
                   "<b>Features:</b><br>" +
                   "• 3-phase 415V distribution cabinet<br>" +
                   "• Up to 4 ways configurable as either:<br>" +
                   "  - 630A disconnects with 630A fuses (for main feeds)<br>" +
                   "  - 2x160A disconnects with 63A fuses (for dual services)<br>" +
                   "  - 1x160A disconnect with 63A fuse and cover plate (for single service)<br>" +
                   "• Configurable cable options for all ways:<br>" +
                   "  - 70mm² to 300mm² for 630A ways<br>" +
                   "  - 16mm² to 50mm² for 160A service ways<br>" +
                   "  - Aluminum or Copper conductor material selection<br>" +
                   "• Optional streetlighting panel with 16A MCBs<br>" +
                   "• Optional service panel for additional connections<br><br>" +
                   "Customize the configuration to match your installation requirements."
        widthFactor: 0.4
        heightFactor: 0.6
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
                        text: "DC-M1 Network Cabinet Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        id: saveButton
                        text: "Save"
                        icon.source: "../../../icons/rounded/save.svg"
                        ToolTip.text: "Save configuration"
                        onClicked: {
                            saveConfigDialog.open()
                        }
                    }

                    StyledButton {
                        id: loadButton
                        text: "Load"
                        icon.source: "../../../icons/rounded/folder_open.svg"
                        ToolTip.text: "Load configuration"
                        onClicked: {
                            loadConfigDialog.open()
                        }
                    }

                    StyledButton {
                        id: exportButton
                        text: "Export PDF"
                        icon.source: "../../../icons/rounded/download.svg"
                        ToolTip.text: "Export configuration to PDF"
                        onClicked: {
                            folderDialog.open()
                        }
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Help"
                        onClicked: popUpText.open()
                    }
                }

                // Configuration panel
                NetworkCabinetConfig {
                    id: cabinetConfig
                    Layout.fillWidth: true
                    Layout.minimumHeight: 400

                    darkMode: cabinetCalculator.darkMode
                    calculator: networkCabinet
                }

                // Visual and notes section
                GridLayout {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 400
                    columns: 2
                    uniformCellWidths: true

                    WaveCard {
                        title: "DC-M1 Network Cabinet"
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        NetworkCabinetDiagram {
                            id: cabinetDiagram
                            anchors.fill: parent
                            darkMode: cabinetCalculator.darkMode
                            calculator: networkCabinet
                            clip: true
                        }
                    }

                    // General Notes card
                    WaveCard {
                        title: "General Notes"
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        TextAreaBlue {
                            id: generalNotesText
                            anchors.fill: parent
                            placeholderText: "Enter general notes about this cabinet configuration..."
                            wrapMode: TextEdit.Wrap
                            text: calculator.generalNotes
                            onTextChanged: calculator.generalNotes = text
                        }
                    }
                }
            }
        }
    }
}
