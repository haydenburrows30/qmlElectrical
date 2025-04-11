import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"

import TransformerLine 1.0
import WindTurbine 1.0

Item {
    id: root

    property var transformerCalculator
    property var windTurbineCalculator

    property bool transformerReady: transformerCalculator !== null
    property bool windTurbineReady: windTurbineCalculator !== null

    property real totalGeneratedPower: windTurbineReady ? windTurbineCalculator.actualPower : 0
    property real windGeneratorCapacity: windTurbineReady ? windTurbineCalculator.actualPower * 1.2 : 0 // 20% margin
    
    Component.onCompleted: {
        transformerCalculator = Qt.createQmlObject('import QtQuick; import TransformerLine 1.0; TransformerLineCalculator {}', 
                                                 root, "dynamicTransformerCalculator");
        windTurbineCalculator = Qt.createQmlObject('import QtQuick; import WindTurbine 1.0; WindTurbineCalculator {}', 
                                                 root, "dynamicWindCalculator");

        windTurbineTimer.running = windTurbineReady
        transformerTimer.running = transformerReady
    }
    
    function safeValue(value, defaultVal) {
        if (value === undefined || value === null) {
            return defaultVal;
        }
        
        if (typeof value !== 'number' || isNaN(value) || !isFinite(value)) {
            return defaultVal;
        }
        
        return value;
    }
    
    // Function to update combined system parameters
    function updateCombinedSystem() {
        if (windTurbineReady && transformerReady) {
            // Get wind turbine output in MVA
            var turbinePower = windTurbineCalculator.actualPower / 1000;
            
            // Update display load MVA for UI purposes
            transformerCalculator.setDisplayLoadMVA(turbinePower);
            
            // Use our special method for updating voltage calculations only without affecting protection settings
            transformerCalculator.updateLoadForVoltageOnly(turbinePower);
            
            // Do NOT call setLoadMVA which would affect protection settings
        }
    }
                
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.topMargin: 5
            
            TabButton {
                text: "Wind Turbine"
            }
            TabButton {
                text: "Transformer & Line"
            }
            TabButton {
                text: "Protection Requirements"
            }
        }
        
        StackLayout {
            Layout.fillWidth: true
            currentIndex: tabBar.currentIndex
            
            // Tab 1: Wind Turbine Parameters
            WindTurbineSection {
                id: windTurbineSection
                Layout.fillWidth: true
                Layout.preferredHeight: 750
                
                // Pass the required properties and functions
                calculator: windTurbineCalculator
                calculatorReady: windTurbineReady
                totalGeneratedPower: root.totalGeneratedPower
                onCalculate: {
                    if (windTurbineReady) {
                        windTurbineCalculator.refreshCalculations()
                        updateCombinedSystem()
                    }
                }
                safeValueFunction: safeValue
            }
            
            // Tab 2: Transformer & Line Parameters
            TransformerLineSection {
                id: transformerLineSection
                Layout.fillWidth: true
                Layout.minimumHeight: 800
                
                // Pass the required properties and functions
                calculator: transformerCalculator
                calculatorReady: transformerReady
                totalGeneratedPower: root.totalGeneratedPower
                onCalculate: {
                    if (transformerReady && windTurbineReady) {
                        // First update wind turbine outputs
                        windTurbineCalculator.refreshCalculations()
                        updateCombinedSystem()
                        // Then calculate transformer system
                        transformerCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }
            
            // Tab 3: Protection Requirements
            ProtectionRequirementsSection {
                Layout.fillWidth: true
                Layout.preferredHeight: 2000 // Increase height to accommodate all content
                
                // Pass the required properties
                transformerCalculator: root.transformerCalculator
                windTurbineCalculator: root.windTurbineCalculator
                transformerReady: root.transformerReady
                windTurbineReady: root.windTurbineReady
                totalGeneratedPower: root.totalGeneratedPower
                
                onCalculate: {
                    if (transformerReady && windTurbineReady) {
                        windTurbineCalculator.refreshCalculations()
                        updateCombinedSystem()
                        transformerCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
        }
    }

    Timer {
        id: windTurbineTimer
        interval: 500
        repeat: true
        running: windTurbineReady
        onTriggered: {
            if (windTurbineReady) {
                updateCombinedSystem()
            }
        }
    }
    
    Timer {
        id: transformerTimer
        interval: 500
        repeat: true
        running: transformerReady
    }
}
