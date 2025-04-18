import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/style"

Item {
    id: root
    
    property var calculator
    property bool darkMode: false
    
    // Signal for notifying config changes
    signal configChanged()
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15
        
        // Number of ways control
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: "Number of Ways:"
                font.bold: true
                Layout.fillWidth: true
            }
            
            SpinBox {
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
                font.bold: true
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
                font.bold: true
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
        
        // Cabinet configuration title
        Label {
            text: "Cabinet Configuration"
            font.bold: true
            font.pixelSize: 16
        }
        
        // Main table with cabinet configuration
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.width: 1
            border.color: darkMode ? "#555555" : "#cccccc"
            
            ListView {
                id: cableListView
                anchors.fill: parent
                anchors.margins: 2
                clip: true
                interactive: true
                
                model: 4
                
                delegate: Rectangle {
                    width: cableListView.width
                    height: 50
                    color: index % 2 === 0 ? 
                           (darkMode ? "#333333" : "#f5f5f5") : 
                           (darkMode ? "#3a3a3a" : "#ffffff")
                    visible: index < (calculator ? calculator.activeWays : 4)
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 8
                        
                        Label {
                            text: "Way " + (index + 1) + ":"
                            font.bold: true
                            Layout.preferredWidth: 60
                        }
                        
                        // Way type selection (630A or 160A options)
                        ComboBox {
                            id: wayTypeCombo
                            objectName: "wayTypeCombo"
                            Layout.preferredWidth: 150
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
                        ComboBox {
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
                        ComboBox {
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
                        
                        // Number of connections selector (for 160A options)
                        ComboBox {
                            id: connectionsCombo
                            objectName: "connectionsCombo"
                            Layout.preferredWidth: 65
                            property int rowIndex: index
                            visible: wayTypeCombo.currentIndex === 1 || wayTypeCombo.currentIndex === 2
                            model: [1, 2, 3, 4, 5, 6]
                            
                            // Set initial index based on calculator data
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
                            
                            Label {
                                anchors {
                                    bottom: parent.top
                                    horizontalCenter: parent.horizontalCenter
                                }
                                text: wayTypeCombo.currentIndex === 1 ? 
                                      "Connections (max 3 per disconnect)" : 
                                      "Connections (max 3)"
                                font.pixelSize: 8
                                font.bold: true
                                color: darkMode ? "#cccccc" : "#666666"
                                width: 150
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }
                        }
                        
                        // Conductor type selection
                        ComboBox {
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
                        ComboBox {
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
                        
                        // Add a spacer to push elements to the right
                        Item {
                            Layout.fillWidth: true
                        }
                        
                        // Replace the individual labels with a combined header section
                        GridLayout {
                            columns: 3
                            rowSpacing: 2
                            columnSpacing: 8
                            Layout.alignment: Qt.AlignRight
                            
                            // Headers
                            Label {
                                text: "Disconnect"
                                font.bold: true
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                Layout.columnSpan: 1
                                Layout.preferredWidth: 65
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: "Fuse"
                                font.bold: true
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                Layout.columnSpan: 1
                                Layout.preferredWidth: 50
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: "Phase"
                                font.bold: true
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                Layout.columnSpan: 1
                                Layout.preferredWidth: 40
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            // Values
                            Label {
                                text: wayTypeCombo.currentIndex === 0 ? "630A" : "160A"
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: 65
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: wayTypeCombo.currentIndex === 0 ? "630A" : "63A"
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: 50
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                color: "#aaaaaa"
                                radius: 15
                                Layout.alignment: Qt.AlignHCenter
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "3Φ"
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Reset button section
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            
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
                    
                    // Emit signal to update connected components
                    configChanged()
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
                waysSpinBox.value = calculator.activeWays
                streetlightingSwitch.checked = calculator.showStreetlightingPanel
                serviceSwitch.checked = calculator.showServicePanel
            }
            
            // Force ListView refresh
            cableListView.forceLayout()
        }
    }
}