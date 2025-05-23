import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import Qt.labs.platform
import QtQuick.Dialogs

import "../../components"
import "../../components/buttons"
import "../../components/style"
import "."  // Add local import to access NetworkCabinetTable

Item {
    id: root
    
    property var calculator
    property bool darkMode: false
    
    // Signal for notifying config changes
    signal configChanged()
    
    RowLayout {
        anchors.fill: parent

        WaveCard {
            title: "Cabinet Settings"
            Layout.maximumWidth: 300
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // Number of Ways
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
                                // Force immediate diagram update
                                cabinetDiagram.updatePanelVisibility()
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
                                // Force immediate diagram update
                                cabinetDiagram.updatePanelVisibility()
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
                        cabinetTable.forceRefresh()
                        
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
            NetworkCabinetTable {
                id: cabinetTable
                anchors.fill: parent
                calculator: root.calculator
                darkMode: root.darkMode
                
                onConfigChanged: {
                    root.configChanged()
                }
            }
        }
    }
    
    // Method to force update all UI controls from calculator values
    function updateUI() {
        if (calculator) {
            // Update all controls from calculator values
            waysSpinBox.value = calculator.activeWays
            
            // Update toggle switches
            streetlightingSwitch.checked = calculator.showStreetlightingPanel
            serviceSwitch.checked = calculator.showServicePanel
            dropperPlatesSwitch.checked = calculator.showDropperPlates
            
            // Force the table component to refresh
            cabinetTable.forceRefresh()
        }
    }
    
    // Watch for calculator changes and refresh UI
    Connections {
        target: calculator
        function onConfigChanged() {
            // Update UI controls when calculator model changes
            if (calculator) {
                // Use the updateUI function to ensure consistent behavior
                updateUI()
            }
        }
        
        // Specific handlers for key properties
        function onShowStreetlightingPanelChanged() {
            if (calculator && streetlightingSwitch.checked !== calculator.showStreetlightingPanel) {
                streetlightingSwitch.checked = calculator.showStreetlightingPanel
            }
        }
        
        function onShowServicePanelChanged() {
            if (calculator && serviceSwitch.checked !== calculator.showServicePanel) {
                serviceSwitch.checked = calculator.showServicePanel
            }
        }
        
        function onShowDropperPlatesChanged() {
            if (calculator && dropperPlatesSwitch.checked !== calculator.showDropperPlates) {
                dropperPlatesSwitch.checked = calculator.showDropperPlates
            }
        }
        
        // Combine these handlers into a single function since they do the same thing
        function onSourcesChanged(sources) { cabinetTable.forceRefresh() }
        function onDestinationsChanged(destinations) { cabinetTable.forceRefresh() }
        function onNotesChanged(notes) { cabinetTable.forceRefresh() }
        function onPhasesChanged(phases) { cabinetTable.forceRefresh() }
    }
}