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
            // Force diagram to update before capture to ensure current settings
            cabinetDiagram.updatePanelVisibility()
            
            // Use Qt.callLater to ensure UI updates have completed
            Qt.callLater(function() {
                // Capture the diagram image
                let diagramImage = cabinetDiagram.captureImage()
                
                // Export to PDF
                calculator.exportToPdf(folderDialog.folder, diagramImage)
            })
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
            
            // Add debug output after loading to check values
            console.log("After loading - Streetlighting: " + calculator.showStreetlightingPanel + 
                        ", Service Panel: " + calculator.showServicePanel +
                        ", Dropper Plates: " + calculator.showDropperPlates)
            
            // Make sure the UI matches the loaded values
            cabinetConfig.updateUI()
            
            // Force update of diagram with explicit delay to ensure model is updated first
            Qt.callLater(function() {
                cabinetDiagram.updatePanelVisibility()
                cabinetDiagram.forceRefresh()
            })
        }
    }
    
    // Status popup for messages
    Popup {
        id: statusPopup
        width: 400
        height: 200
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

    // Main
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            id: flickableMain
            contentWidth: parent.width
            contentHeight: tabContentLayout.height + 70
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
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: {
                            saveConfigDialog.open()
                        }
                    }

                    StyledButton {
                        id: loadButton
                        text: "Load"
                        icon.source: "../../../icons/rounded/folder_open.svg"
                        ToolTip.text: "Load configuration"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: {
                            loadConfigDialog.open()
                        }
                    }

                    StyledButton {
                        id: exportButton
                        text: "Export PDF"
                        icon.source: "../../../icons/rounded/download.svg"
                        ToolTip.text: "Export configuration to PDF"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: {
                            folderDialog.open()
                        }
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Help"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                // TabBar for switching between configuration views
                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    
                    TabButton {
                        text: "Cabinet Config"
                    }
                    
                    TabButton {
                        text: "Site & Document Info"
                    }
                }

                // Tab content with StackLayout
                StackLayout {
                    id: tabContentLayout
                    Layout.fillWidth: true
                    currentIndex: tabBar.currentIndex
                    
                    // Tab 1: Cabinet Configuration tab content
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: cabinetContentLayout.implicitHeight
                        
                        ColumnLayout {
                            id: cabinetContentLayout
                            width: parent.width
                            
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
                    
                    // Tab 2: Site & Document Info tab content
                    ColumnLayout {
                        width: parent.width

                        RowLayout {

                            // Site Information Section
                            WaveCard {
                                title: "Site Information"
                                Layout.fillWidth: true
                                Layout.minimumHeight: 150
                                Layout.alignment: Qt.AlignTop
                                
                                GridLayout {
                                    id: siteInfoLayout
                                    anchors.fill: parent
                                    columns: 2
                                    
                                    Label {
                                        text: "Site Name:"
                                        Layout.minimumWidth: 150
                                    }
                                    
                                    TextFieldRound {
                                        id: siteNameField
                                        Layout.fillWidth: true
                                        placeholderText: "Enter site name"
                                        selectByMouse: true
                                        text: calculator.siteName
                                        onTextChanged: calculator.siteName = text
                                    }
                                    
                                    Label {
                                        text: "Site Number:"
                                        Layout.minimumWidth: 150
                                    }
                                    
                                    TextFieldRound {
                                        id: siteNumberField
                                        Layout.fillWidth: true
                                        placeholderText: "Enter site number"
                                        selectByMouse: true
                                        text: calculator.siteNumber
                                        onTextChanged: calculator.siteNumber = text
                                    }
                                }
                            }
                                                        
                            // Header Section
                            WaveCard {
                                title: "Document Header"
                                Layout.fillWidth: true
                                Layout.minimumHeight: 200
                                
                                GridLayout {
                                    id: headerSection
                                    anchors.fill: parent
                                    columns: 2
                                    
                                    Label {
                                        text: "Customer Name:"
                                        Layout.minimumWidth: 150
                                    }
                                    
                                    TextFieldRound {
                                        Layout.fillWidth: true
                                        placeholderText: "Enter customer name"
                                        text: calculator.customerName
                                        onTextChanged: calculator.customerName = text
                                    }
                                    
                                    Label {
                                        text: "Customer Email:"
                                        Layout.minimumWidth: 150
                                    }
                                    
                                    TextFieldRound {
                                        Layout.fillWidth: true
                                        placeholderText: "Enter customer email"
                                        text: calculator.customerEmail
                                        onTextChanged: calculator.customerEmail = text
                                    }
                                    
                                    Label {
                                        text: "Project Name:"
                                        Layout.minimumWidth: 150
                                    }
                                    
                                    TextFieldRound {
                                        Layout.fillWidth: true
                                        placeholderText: "Enter project name"
                                        text: calculator.projectName
                                        onTextChanged: calculator.projectName = text
                                    }
                                    
                                    Label {
                                        text: "ORN:"
                                        Layout.minimumWidth: 150
                                    }
                                    
                                    TextFieldRound {
                                        Layout.fillWidth: true
                                        placeholderText: "Enter ORN"
                                        text: calculator.orn
                                        onTextChanged: calculator.orn = text
                                    }
                                }
                            }

                                                    
                        // Cabinet Configuration Summary Section (new section)
                        WaveCard {
                            title: "Cabinet Configuration Summary"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 200
                            
                            GridLayout {
                                id: cabinetSummaryLayout
                                anchors.fill: parent
                                anchors.margins: 15
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 10
                                
                                Label {
                                    text: "Number of Ways:"
                                    Layout.minimumWidth: 200
                                }
                                
                                Label {
                                    text: calculator ? calculator.activeWays : "4"
                                    Layout.fillWidth: true
                                    font.bold: true
                                }
                                
                                Label {
                                    text: "Streetlighting Panel:"
                                    Layout.minimumWidth: 200
                                }
                                
                                Label {
                                    text: calculator && calculator.showStreetlightingPanel ? "Included" : "Not Included"
                                    Layout.fillWidth: true
                                    font.bold: true
                                }
                                
                                Label {
                                    text: "Local Service Panel:"
                                    Layout.minimumWidth: 200
                                }
                                
                                Label {
                                    text: calculator && calculator.showServicePanel ? "Included" : "Not Included"
                                    Layout.fillWidth: true
                                    font.bold: true
                                }
                                
                                Label {
                                    text: "Dropper Plates:"
                                    Layout.minimumWidth: 200
                                }
                                
                                Label {
                                    text: calculator && calculator.showDropperPlates ? "Included" : "Not Included"
                                    Layout.fillWidth: true
                                    font.bold: true
                                }
                            }
                        }
                        }
                        
                        // Revisions Section
                        WaveCard {
                            title: "Revisions"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 360
                            
                            ColumnLayout {
                                id: revisionsLayout
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: "Number of revisions:"
                                    }
                                    
                                    SpinBox {
                                        id: revisionCountSpinBox
                                        from: 1
                                        to: 5
                                        value: calculator ? calculator.revisionCount : 1
                                        
                                        onValueChanged: {
                                            if (calculator) {
                                                calculator.revisionCount = value;
                                            }
                                        }
                                    }
                                }
                                    
                                RowLayout {
                                    width: parent.width
                                    
                                    Repeater {
                                        id: revisionRepeater
                                        model: calculator ? calculator.revisionCount : 1
                                        
                                        delegate: Frame {
                                            Layout.fillWidth: true
                                            
                                            background: Rectangle {
                                                color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"
                                                border.color: "#cccccc"
                                                radius: 5
                                            }
                                            
                                            GridLayout {
                                                anchors.fill: parent
                                                columns: 2
                                                
                                                Label {
                                                    text: "Revision " + (index + 1) + ":"
                                                    font.bold: true
                                                    Layout.columnSpan: 2
                                                }
                                                
                                                Label {
                                                    text: "Revision No.:"
                                                    Layout.minimumWidth: 100
                                                }
                                                
                                                TextFieldRound {
                                                    Layout.fillWidth: true
                                                    placeholderText: (index + 1).toString()
                                                    property bool updating: false
                                                    
                                                    Component.onCompleted: {
                                                        if (calculator && calculator.revisions && index < calculator.revisions.length) {
                                                            let num = calculator.getRevisionProperty(index, "number");
                                                            if (num) {
                                                                text = num;
                                                            } else {
                                                                text = (index + 1).toString();
                                                            }
                                                        } else {
                                                            text = (index + 1).toString();
                                                        }
                                                    }
                                                    
                                                    onTextChanged: {
                                                        if (!updating && calculator) {
                                                            updating = true;
                                                            calculator.setRevisionProperty(index, "number", text);
                                                            updating = false;
                                                        }
                                                    }
                                                }
                                                
                                                Label {
                                                    text: "Description:"
                                                    Layout.minimumWidth: 180
                                                }
                                                
                                                TextFieldRound {
                                                    Layout.fillWidth: true
                                                    placeholderText: "Enter revision description"
                                                    property bool updating: false
                                                    
                                                    Component.onCompleted: {
                                                        if (calculator && calculator.revisions && index < calculator.revisions.length) {
                                                            let desc = calculator.getRevisionProperty(index, "description");
                                                            if (desc) {
                                                                text = desc;
                                                            } else {
                                                                text = "";
                                                            }
                                                        } else {
                                                            text = "";
                                                        }
                                                    }
                                                    
                                                    onTextChanged: {
                                                        if (!updating && calculator) {
                                                            updating = true;
                                                            calculator.setRevisionProperty(index, "description", text);
                                                            updating = false;
                                                        }
                                                    }
                                                }
                                                
                                                Label {
                                                    text: "Designer:"
                                                    Layout.minimumWidth: 120
                                                }
                                                
                                                TextFieldRound {
                                                    Layout.fillWidth: true
                                                    placeholderText: "Enter designer name"
                                                    property bool updating: false
                                                    
                                                    Component.onCompleted: {
                                                        if (calculator && calculator.revisions && index < calculator.revisions.length) {
                                                            let designer = calculator.getRevisionProperty(index, "designer");
                                                            if (designer) {
                                                                text = designer;
                                                            } else if (calculator && calculator.designer) {
                                                                text = calculator.designer;
                                                            } else {
                                                                text = "";
                                                            }
                                                        } else if (calculator && calculator.designer) {
                                                            text = calculator.designer;
                                                        } else {
                                                            text = "";
                                                        }
                                                    }
                                                    
                                                    onTextChanged: {
                                                        if (!updating && calculator) {
                                                            updating = true;
                                                            calculator.setRevisionProperty(index, "designer", text);
                                                            // Set the main designer property if this is the first revision
                                                            if (index === 0 && (!calculator.designer || calculator.designer === "")) {
                                                                calculator.designer = text;
                                                            }
                                                            updating = false;
                                                        }
                                                    }
                                                }
                                                
                                                Label {
                                                    text: "Date:"
                                                    Layout.minimumWidth: 120
                                                }
                                                
                                                TextFieldRound {
                                                    Layout.fillWidth: true
                                                    placeholderText: Qt.formatDate(new Date(), "dd/MM/yyyy")
                                                    property bool updating: false
                                                    
                                                    Component.onCompleted: {
                                                        if (calculator && calculator.revisions && index < calculator.revisions.length) {
                                                            let date = calculator.getRevisionProperty(index, "date");
                                                            if (date) {
                                                                text = date;
                                                            } else {
                                                                text = "";
                                                            }
                                                        } else {
                                                            text = "";
                                                        }
                                                    }
                                                    
                                                    onTextChanged: {
                                                        if (!updating && calculator) {
                                                            updating = true;
                                                            calculator.setRevisionProperty(index, "date", text);
                                                            updating = false;
                                                        }
                                                    }
                                                }
                                                
                                                Label {
                                                    text: "Checked by:"
                                                    Layout.minimumWidth: 120
                                                }
                                                
                                                TextFieldRound {
                                                    Layout.fillWidth: true
                                                    placeholderText: "Enter checker name"
                                                    property bool updating: false
                                                    
                                                    Component.onCompleted: {
                                                        if (calculator && calculator.revisions && index < calculator.revisions.length) {
                                                            let checker = calculator.getRevisionProperty(index, "checkedBy");
                                                            if (checker) {
                                                                text = checker;
                                                            } else if (calculator && calculator.checkedBy) {
                                                                text = calculator.checkedBy;
                                                            } else {
                                                                text = "";
                                                            }
                                                        } else if (calculator && calculator.checkedBy) {
                                                            text = calculator.checkedBy;
                                                        } else {
                                                            text = "";
                                                        }
                                                    }
                                                    
                                                    onTextChanged: {
                                                        if (!updating && calculator) {
                                                            updating = true;
                                                            calculator.setRevisionProperty(index, "checkedBy", text);
                                                            // Set the main checker property if this is the first revision
                                                            if (index === 0 && (!calculator.checkedBy || calculator.checkedBy === "")) {
                                                                calculator.checkedBy = text;
                                                            }
                                                            updating = false;
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
                }
            }
        }
    }
}
