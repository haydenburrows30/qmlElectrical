import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import Qt.labs.platform
import QtQuick.Dialogs

// Add import for validators
import QtCore

import "../../components"
import "../../components/buttons"
import "../../components/style"

Item {
    id: root
    
    property var calculator
    property bool darkMode: false
    
    // Signal for notifying config changes
    signal configChanged()
    
    RowLayout {
        anchors.fill: parent
        
        WaveCard {
            title: "Site Information"
            Layout.maximumWidth: 300
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // Site information controTextFieldRound {ls
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Site Name:"
                        Layout.preferredWidth: 100
                    }
                    
                    TextFieldRound {
                        id: siteNameField
                        Layout.fillWidth: true
                        placeholderText: "Enter site name"
                        selectByMouse: true
                        text: calculator ? calculator.siteName : ""
                        
                        onTextChanged: {
                            if (calculator && calculator.siteName !== text) {
                                calculator.siteName = text
                                configChanged()
                            }
                        }
                    }
                }

                // Site Name
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Site Number:"
                        Layout.preferredWidth: 100
                    }
                    
                    TextFieldRound {
                        id: siteNumberField
                        Layout.fillWidth: true
                        placeholderText: "Enter site number"
                        selectByMouse: true
                        text: calculator ? calculator.siteNumber : ""
                        
                        onTextChanged: {
                            if (calculator && calculator.siteNumber !== text) {
                                calculator.siteNumber = text
                                configChanged()
                            }
                        }
                    }
                }

                // Site Number
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Number of Ways:"
                        Layout.fillWidth: true
                    }
                    
                    SpinBoxRound {
                        id: waysSpinBox
                        from: 1
                        to: 4
                        value: calculator ? calculator.activeWays : 4
                        
                        onValueChanged: {
                            if (calculator && calculator.activeWays !== value) {
                                calculator.activeWays = value
                                configChanged()
                            }
                        }
                    }
                }
                
                // Streetlighting toggle
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Streetlighting Panel:"
                        Layout.fillWidth: true
                    }
                    
                    Switch {
                        id: streetlightingSwitch
                        checked: calculator ? calculator.showStreetlightingPanel : true
                        
                        onCheckedChanged: {
                            if (calculator && calculator.showStreetlightingPanel !== checked) {
                                calculator.showStreetlightingPanel = checked
                                configChanged()
                            }
                        }
                    }
                }
                
                // Service panel toggle
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Local Service Panel:"
                        Layout.fillWidth: true
                    }
                    
                    Switch {
                        id: serviceSwitch
                        checked: calculator ? calculator.showServicePanel : true
                        
                        onCheckedChanged: {
                            if (calculator && calculator.showServicePanel !== checked) {
                                calculator.showServicePanel = checked
                                configChanged()
                            }
                        }
                    }
                }

                // Dropper Plates toggle
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Dropper Plates:"
                        Layout.fillWidth: true
                    }
                    
                    Switch {
                        id: dropperPlatesSwitch
                        checked: calculator ? calculator.showDropperPlates : false
                        
                        onCheckedChanged: {
                            if (calculator && calculator.showDropperPlates !== checked) {
                                calculator.showDropperPlates = checked
                                configChanged()
                            }
                        }
                    }
                }

                // Reset button
                StyledButton {
                    text: "Reset to Default"
                    icon.source: "../../../icons/rounded/refresh.svg"
                    Layout.fillWidth: true
                    
                    onClicked: {
                        if (calculator) {
                            calculator.resetToDefaults()
                        }
                        
                        // Force UI refresh
                        cableListView.forceLayout()
                        
                        // Clear the text fields
                        for (var i = 0; i < cableListView.count; i++) {
                            var sourceField = cableListView.itemAtIndex(i)?.findChild("sourceField")
                            var destinationField = cableListView.itemAtIndex(i)?.findChild("destinationField")
                            var notesField = cableListView.itemAtIndex(i)?.findChild("notesField")
                            var lengthField = cableListView.itemAtIndex(i)?.findChild("lengthField")
                            
                            if (sourceField) sourceField.text = ""
                            if (destinationField) destinationField.text = ""
                            if (notesField) notesField.text = ""
                            if (lengthField) lengthField.text = ""
                        }
                        
                        // Clear service panel text fields
                        if (servicePanelSourceField) servicePanelSourceField.text = ""
                        if (servicePanelDestinationField) servicePanelDestinationField.text = ""
                        if (servicePanelNotesField) servicePanelNotesField.text = ""
                        if (servicePanelLengthField) servicePanelLengthField.text = ""
                        
                        // Emit signal to update connected components
                        configChanged()
                    }
                }

                Label {Layout.fillHeight: true}
            }
        }

        WaveCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            titleVisible: false

            // Main table with cabinet configuration
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Column headers for the table
                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    color: darkMode ? "#444444" : "#e0e0e0"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        spacing: 8
                        
                        Label {
                            text: "Way"
                            font.bold: true
                            Layout.preferredWidth: 30
                        }
                        
                        Label {
                            text: "Type"
                            font.bold: true
                            Layout.preferredWidth: 160
                        }
                        
                        Label {
                            text: "Cable Size"
                            font.bold: true
                            Layout.preferredWidth: 105
                        }

                        Label {
                            text: "Material"
                            font.bold: true
                            Layout.preferredWidth: 70
                        }

                        Label {
                            text: "Source"
                            font.bold: true
                            Layout.preferredWidth: 120
                        }
                        
                        Label {
                            text: "Destination"
                            font.bold: true
                            Layout.preferredWidth: 120
                        }
                        
                        Label {
                            text: "Length"
                            font.bold: true
                            Layout.preferredWidth: 80
                        }
                        
                        Label {
                            text: "Notes"
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Label {
                            id: connectionsHeaderLabel
                            text: "Connections"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 65
                            Layout.alignment: Qt.AlignHCenter
                            
                            visible: {
                                if (calculator && calculator.showServicePanel) {
                                    return true;
                                }
                                
                                if (calculator && calculator.wayTypes) {
                                    for (var i = 0; i < calculator.activeWays; i++) {
                                        if (calculator.wayTypes[i] === 1 || calculator.wayTypes[i] === 2) {
                                            return true;
                                        }
                                    }
                                }
                                
                                return false;
                            }
                        }

                        Label {
                            text: "Fuse"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: "Phase"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                ListView {
                    id: cableListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    interactive: true
                    model: 4
                    
                    delegate: Rectangle {
                        width: cableListView.width
                        height: 60
                        color: index % 2 === 0 ? 
                            (darkMode ? "#333333" : "#f5f5f5") : 
                            (darkMode ? "#3a3a3a" : "#ffffff")
                        visible: index < (calculator ? calculator.activeWays : 4)
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 8
                            
                            Label {
                                text: (index + 1) + ":"
                                font.bold: true
                                Layout.preferredWidth: 30
                            }
                            
                            // Way type selection (630A or 160A options)
                            ComboBoxRound {
                                id: wayTypeCombo
                                objectName: "wayTypeCombo"
                                Layout.preferredWidth: 160
                                model: ["630A Disconnect", "2x160A Services", "1x160A + Cover"]
                                
                                property int rowIndex: index
                                
                                // Set initial index based on calculator data
                                currentIndex: calculator && calculator.wayTypes && rowIndex < calculator.wayTypes.length ? 
                                            calculator.wayTypes[rowIndex] : 0
                                
                                onActivated: function(controlIndex) {
                                    if (calculator) {
                                        calculator.setWayType(rowIndex, currentIndex)
                                        configChanged()
                                    }
                                }
                            }
                            
                            // Cable size selection for 630A disconnects
                            ComboBoxRound {
                                id: cableSizeCombo
                                objectName: "cableSizeCombo"
                                Layout.preferredWidth: 100
                                property int rowIndex: index
                                enabled: rowIndex < (calculator ? calculator.activeWays : 4) && wayTypeCombo.currentIndex === 0
                                visible: wayTypeCombo.currentIndex === 0
                                model: ["300mm²", "240mm²", "185mm²", "150mm²", "120mm²", "95mm²", "70mm²"]
                                
                                // Set initial index based on calculator data
                                currentIndex: {
                                    if (calculator && calculator.cableSizes && rowIndex < calculator.cableSizes.length) {
                                        var idx = model.indexOf(calculator.cableSizes[rowIndex])
                                        return idx >= 0 ? idx : 0
                                    }
                                    return 0
                                }
                                
                                onCurrentTextChanged: function() {
                                    if (calculator && rowIndex < calculator.cableSizes.length) {
                                        calculator.setCableSize(rowIndex, currentText)
                                        configChanged()
                                    }
                                }
                            }
                            
                            // Cable size selection for 160A services
                            ComboBoxRound {
                                id: serviceCableSizeCombo
                                objectName: "serviceCableSizeCombo"
                                Layout.preferredWidth: 100
                                property int rowIndex: index
                                visible: wayTypeCombo.currentIndex === 1 || wayTypeCombo.currentIndex === 2
                                model: ["16mm²", "25mm²", "35mm²", "50mm²"]
                                
                                // Set initial index based on calculator data
                                currentIndex: {
                                    if (calculator && calculator.serviceCableSizes && rowIndex < calculator.serviceCableSizes.length) {
                                        var idx = model.indexOf(calculator.serviceCableSizes[rowIndex])
                                        return idx >= 0 ? idx : 2  // Default to 35mm²
                                    }
                                    return 2  // Default to 35mm²
                                }
                                
                                onCurrentTextChanged: function() {
                                    if (calculator && visible && rowIndex < calculator.serviceCableSizes.length) {
                                        calculator.setServiceCableSize(rowIndex, currentText)
                                        configChanged()
                                    }
                                }
                            }

                            // Conductor type selection
                            ComboBoxRound {
                                id: conductorTypeCombo
                                objectName: "conductorTypeCombo"
                                Layout.preferredWidth: 70
                                property int rowIndex: index
                                visible: wayTypeCombo.currentIndex === 0
                                model: ["Al", "Cu"]
                                
                                // Set initial index based on calculator data
                                currentIndex: {
                                    if (calculator && calculator.conductorTypes && rowIndex < calculator.conductorTypes.length) {
                                        var idx = model.indexOf(calculator.conductorTypes[rowIndex])
                                        return idx >= 0 ? idx : 0
                                    }
                                    return 0
                                }
                                
                                onCurrentTextChanged: function() {
                                    if (calculator && rowIndex < calculator.conductorTypes.length) {
                                        calculator.setConductorType(rowIndex, currentText)
                                        configChanged()
                                    }
                                }
                            }

                            // Service conductor type selection
                            ComboBoxRound {
                                id: serviceConductorTypeCombo
                                objectName: "serviceConductorTypeCombo"
                                Layout.preferredWidth: 70
                                property int rowIndex: index
                                visible: wayTypeCombo.currentIndex === 1 || wayTypeCombo.currentIndex === 2
                                model: ["Al", "Cu"]
                                
                                // Set initial index based on calculator data
                                currentIndex: {
                                    if (calculator && calculator.serviceConductorTypes && 
                                        rowIndex < calculator.serviceConductorTypes.length) {
                                        var idx = model.indexOf(calculator.serviceConductorTypes[rowIndex])
                                        return idx >= 0 ? idx : 0
                                    }
                                    return 0
                                }
                                
                                onCurrentTextChanged: function() {
                                    if (calculator && rowIndex < calculator.serviceConductorTypes.length) {
                                        calculator.setServiceConductorType(rowIndex, currentText)
                                        configChanged()
                                    }
                                }
                            }

                            // Source
                            TextFieldRound {
                                id: sourceField
                                objectName: "sourceField"
                                Layout.preferredWidth: 120
                                placeholderText: "Source"
                                selectByMouse: true
                                property int rowIndex: index
                                
                                onTextChanged: {
                                    if (calculator) {
                                        calculator.setSource(rowIndex, text)
                                    }
                                }
                            }

                            // Destination
                            TextFieldRound {
                                id: destinationField
                                objectName: "destinationField"
                                Layout.preferredWidth: 120
                                placeholderText: "Destination"
                                selectByMouse: true
                                property int rowIndex: index
                                
                                onTextChanged: {
                                    if (calculator) {
                                        calculator.setDestination(rowIndex, text)
                                    }
                                }
                            }

                            // Length
                            TextFieldRound {
                                id: lengthField
                                objectName: "lengthField"
                                Layout.preferredWidth: 80
                                placeholderText: "Length"
                                selectByMouse: true
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: IntValidator {
                                    bottom: 0
                                }
                                
                                property int rowIndex: index
                                text: calculator && calculator.cableLengths && rowIndex < calculator.cableLengths.length && 
                                      calculator.cableLengths[rowIndex] > 0 ? Math.round(calculator.cableLengths[rowIndex]).toString() : ""
                                
                                onTextChanged: {
                                    if (calculator && rowIndex < calculator.cableLengths.length) {
                                        var length = parseInt(text, 10)
                                        if (!isNaN(length)) {
                                            calculator.setCableLength(rowIndex, length)
                                            configChanged()
                                        }
                                    }
                                }
                            }

                            // Notes
                            TextFieldRound {
                                id: notesField
                                objectName: "notesField"
                                Layout.fillWidth: true
                                placeholderText: "Notes"
                                selectByMouse: true
                                property int rowIndex: index
                                
                                onTextChanged: {
                                    if (calculator) {
                                        calculator.setNotes(rowIndex, text)
                                    }
                                }
                            }

                            // Number of connections selector (for 160A options)
                            ComboBoxRound {
                                id: connectionsCombo
                                objectName: "connectionsCombo"
                                Layout.preferredWidth: 65
                                property int rowIndex: index
                                visible: (wayTypeCombo.currentIndex === 1 || wayTypeCombo.currentIndex === 2) && connectionsHeaderLabel.visible
                                model: wayTypeCombo.currentIndex === 2 ? [1, 2, 3] : [1, 2, 3, 4, 5, 6]
                                
                                currentIndex: {
                                    if (calculator && calculator.connectionCounts && rowIndex < calculator.connectionCounts.length) {
                                        var count = calculator.connectionCounts[rowIndex]
                                        return (count >= 1 && count <= 6) ? count - 1 : 1
                                    }
                                    return 1
                                }
                                
                                onCurrentIndexChanged: function() {
                                    if (calculator && visible && rowIndex < calculator.connectionCounts.length) {
                                        calculator.setConnectionCount(rowIndex, currentIndex + 1)
                                        configChanged()
                                    }
                                }
                            }

                            // Fuse size
                            Label {
                                text: wayTypeCombo.currentIndex === 0 ? "LINK" : "63A"
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: 40
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // No. of phases
                            RoundButton {
                                id: phaseButton1
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignHCenter
                                property int rowIndex: index

                                ToolTip.text: "Click to change phase"
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                
                                // Initialize text from calculator's phases array
                                Component.onCompleted: {
                                    if (calculator && calculator.phases && rowIndex < calculator.phases.length) {
                                        phaseButton1.text = calculator.phases[rowIndex]
                                    }
                                }
                                
                                onClicked: {
                                    if (phaseButton1.text === "3Φ") {
                                        phaseButton1.text = "1Φ"
                                    } else {
                                        phaseButton1.text = "3Φ"
                                    }
                                    
                                    // Update the calculator with the phase information
                                    if (calculator) {
                                        calculator.setPhase(rowIndex, phaseButton1.text)
                                    }
                                }
                                text: "3Φ"
                            }
                        }
                    }
                }
                
                // Add service panel row when enabled
                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    color: darkMode ? "#333333" : "#f5f5f5"
                    visible: calculator ? calculator.showServicePanel : true
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 8
                        
                        Label {
                            text: "SR:"
                            font.bold: true
                            Layout.preferredWidth: 30
                        }
                        
                        // Fixed type - similar to 1x160A
                        Label {
                            text: "160A Disconnect"
                            Layout.preferredWidth: 160
                        }
                        
                        // Cable size selection for service panel
                        ComboBoxRound {
                            id: servicePanelCableSizeCombo
                            objectName: "servicePanelCableSizeCombo"
                            Layout.preferredWidth: 100
                            model: ["16mm²", "25mm²", "35mm²", "50mm²"]
                            
                            // Set initial index based on calculator data
                            currentIndex: {
                                if (calculator && calculator.servicePanelCableSize) {
                                    var idx = model.indexOf(calculator.servicePanelCableSize)
                                    return idx >= 0 ? idx : 2  // Default to 35mm²
                                }
                                return 2  // Default to 35mm²
                            }
                            
                            onCurrentTextChanged: function() {
                                if (calculator) {
                                    calculator.servicePanelCableSize = currentText
                                    configChanged()
                                }
                            }
                        }
                        
                        // Service conductor type selection
                        ComboBoxRound {
                            id: servicePanelConductorTypeCombo
                            objectName: "servicePanelConductorTypeCombo"
                            Layout.preferredWidth: 70
                            model: ["Al", "Cu"]
                            
                            // Set initial index based on calculator data
                            currentIndex: {
                                if (calculator && calculator.servicePanelConductorType) {
                                    var idx = model.indexOf(calculator.servicePanelConductorType)
                                    return idx >= 0 ? idx : 0
                                }
                                return 0
                            }
                            
                            onCurrentTextChanged: function() {
                                if (calculator) {
                                    calculator.servicePanelConductorType = currentText
                                    configChanged()
                                }
                            }
                        }
                        
                        // Source
                        TextFieldRound {
                            id: servicePanelSourceField
                            Layout.preferredWidth: 120
                            placeholderText: "Source"
                            selectByMouse: true
                            
                            onTextChanged: {
                                if (calculator) {
                                    calculator.servicePanelSource = text
                                }
                            }
                        }

                        // Destination
                        TextFieldRound {
                            id: servicePanelDestinationField
                            Layout.preferredWidth: 120
                            placeholderText: "Destination"
                            selectByMouse: true
                            
                            onTextChanged: {
                                if (calculator) {
                                    calculator.servicePanelDestination = text
                                }
                            }
                        }

                        // Length
                        TextFieldRound {
                            id: servicePanelLengthField
                            objectName: "servicePanelLengthField"
                            Layout.preferredWidth: 80
                            placeholderText: "Length"
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator {
                                bottom: 0
                            }
                            
                            text: calculator && calculator.servicePanelLength > 0 ? 
                                  Math.round(calculator.servicePanelLength).toString() : ""
                            
                            onTextChanged: {
                                if (calculator) {
                                    var length = parseInt(text, 10)
                                    if (!isNaN(length)) {
                                        calculator.servicePanelLength = length
                                    }
                                }
                            }
                        }

                        // Notes
                        TextFieldRound {
                            id: servicePanelNotesField
                            Layout.fillWidth: true
                            placeholderText: "Notes"
                            selectByMouse: true
                            
                            onTextChanged: {
                                if (calculator) {
                                    calculator.servicePanelNotes = text
                                }
                            }
                        }

                        // Number of connections selector
                        ComboBoxRound {
                            id: servicePanelConnectionsCombo
                            objectName: "servicePanelConnectionsCombo"
                            Layout.preferredWidth: 65
                            visible: connectionsHeaderLabel.visible
                            model: [1, 2, 3]
                            
                            currentIndex: {
                                if (calculator && calculator.servicePanelConnectionCount) {
                                    var count = calculator.servicePanelConnectionCount
                                    return (count >= 1 && count <= 6) ? count - 1 : 1
                                }
                                return 1
                            }
                            
                            onCurrentIndexChanged: function() {
                                if (calculator) {
                                    calculator.servicePanelConnectionCount = currentIndex + 1
                                    configChanged()
                                }
                            }
                        }

                        // Fuse size
                        Label {
                            text: "63A"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 40
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        // No. of phases
                        RoundButton {
                            id: phaseButton
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter

                            ToolTip.text: "Click to change phase"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                            
                            // Initialize text from calculator's service panel phase
                            Component.onCompleted: {
                                if (calculator && calculator.servicePanelPhase) {
                                    phaseButton.text = calculator.servicePanelPhase
                                }
                            }

                            onClicked: {
                                if (phaseButton.text === "3Φ") {
                                    phaseButton.text = "1Φ"
                                } else {
                                    phaseButton.text = "3Φ"
                                }
                                
                                // Update the calculator with the phase information
                                if (calculator) {
                                    calculator.servicePanelPhase = phaseButton.text
                                }
                            }
                            text: "3Φ"
                        }
                    }
                }
            }
        }
    }
    
    // Watch for calculator changes and refresh UI
    Connections {
        target: calculator
        function onConfigChanged() {
            // Update UI controls when calculator model changes
            if (calculator) {
                // Manually update the ways spinbox first to ensure correct rendering
                if (waysSpinBox.value !== calculator.activeWays) {
                    waysSpinBox.value = calculator.activeWays
                }
                
                siteNameField.text = calculator.siteName
                siteNumberField.text = calculator.siteNumber
                streetlightingSwitch.checked = calculator.showStreetlightingPanel
                serviceSwitch.checked = calculator.showServicePanel
                dropperPlatesSwitch.checked = calculator.showDropperPlates
                
                // Update service panel controls if they exist
                if (calculator.showServicePanel) {
                    servicePanelCableSizeCombo.currentIndex = 
                        servicePanelCableSizeCombo.model.indexOf(calculator.servicePanelCableSize)
                    servicePanelConductorTypeCombo.currentIndex = 
                        servicePanelConductorTypeCombo.model.indexOf(calculator.servicePanelConductorType)
                    servicePanelConnectionsCombo.currentIndex = calculator.servicePanelConnectionCount - 1
                    
                    servicePanelSourceField.text = calculator.servicePanelSource
                    servicePanelDestinationField.text = calculator.servicePanelDestination
                    servicePanelNotesField.text = calculator.servicePanelNotes
                    
                    // Update length field if available
                    if (calculator.servicePanelLength > 0) {
                        servicePanelLengthField.text = Math.round(calculator.servicePanelLength).toString()
                    } else {
                        servicePanelLengthField.text = ""
                    }
                }
                
                // Force ListView to refresh for the cable ways
                cableListView.forceLayout()
            }
        }
    }
}