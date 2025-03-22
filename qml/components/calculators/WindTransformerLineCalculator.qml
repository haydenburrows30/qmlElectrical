import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import TransformerLine 1.0
import WindTurbine 1.0

Item {
    id: root
    anchors.fill: parent
    
    // Import the calculators
    property var transformerCalculator
    property var windTurbineCalculator
    
    // Properties to prevent null errors
    property bool transformerReady: transformerCalculator !== null
    property bool windTurbineReady: windTurbineCalculator !== null
    
    // Combined calculated values
    property real totalGeneratedPower: windTurbineReady ? windTurbineCalculator.powerInKW : 0
    property real windGeneratorCapacity: windTurbineReady ? windTurbineCalculator.powerInKW * 1.2 : 0 // 20% margin
    
    Component.onCompleted: {
        // Create calculator instances
        transformerCalculator = Qt.createQmlObject('import QtQuick; import TransformerLine 1.0; TransformerLineCalculator {}', 
                                                 root, "dynamicTransformerCalculator");
        windTurbineCalculator = Qt.createQmlObject('import QtQuick; import WindTurbine 1.0; WindTurbineCalculator {}', 
                                                 root, "dynamicWindCalculator");
        
        // Start timers when ready
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
            // Update transformer load based on wind turbine output
            // Wind turbine output in kW, transformer needs MVA
            var turbinePower = windTurbineCalculator.powerInKW / 1000;
            transformerCalculator.setLoadMVA(turbinePower);
        }
    }
                
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 20
        
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
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
                Layout.preferredHeight: 750 // Ensure enough height
                
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
                Layout.minimumHeight: 800 // Ensure enough height
                
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
        
        // Add a spacer item at the bottom to ensure there's scrollable space
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
        }
    }
    
    // Add polling timers to update UI state instead of relying on signals
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
