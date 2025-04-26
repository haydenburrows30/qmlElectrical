import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import "../../components/style"
import "../../components/buttons"
import "../../components/navigation"

import TransformerLine 1.0
import WindTurbine 1.0

Item {
    id: root
    property TransformerLineCalculator transformerCalculator : TransformerLineCalculator {}
    property WindTurbineCalculator windTurbineCalculator : WindTurbineCalculator {}
    
    property bool transformerReady: transformerCalculator !== null
    property bool windTurbineReady: windTurbineCalculator !== null
    property real totalGeneratedPower: windTurbineReady ? windTurbineCalculator.actualPower : 0
    
    function safeValue(value, defaultVal) {
        if (value === undefined || value === null) {
            return defaultVal;
        }
        
        if (typeof value !== 'number' || isNaN(value) || !isFinite(value)) {
            return defaultVal;
        }
        
        return value;
    }
                
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0
        
        // Main content stack
        StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            
            // Tab 1: Wind Turbine Parameters - operates independently
            WindTurbineSection {
                id: windTurbineSection
                Layout.fillWidth: true

                // Pass only necessary properties and functions
                calculator: windTurbineCalculator
                calculatorReady: windTurbineReady

                onCalculate: {
                    if (windTurbineReady) {
                        windTurbineCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }

            // Tab 2: Transformer & Line Parameters - operates independently
            TransformerLineSection {
                id: transformerLineSection
                Layout.fillWidth: true

                // Pass only necessary properties and functions
                calculator: transformerCalculator
                calculatorReady: transformerReady

                onCalculate: {
                    if (transformerReady) {
                        transformerCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }

            // Tab 3: Protection Requirements - still needs access to both
            ProtectionRequirementsSection {
                Layout.fillWidth: true

                // Pass the required properties
                transformerCalculator: root.transformerCalculator
                windTurbineCalculator: root.windTurbineCalculator
                transformerReady: root.transformerReady
                windTurbineReady: root.windTurbineReady
                totalGeneratedPower: root.totalGeneratedPower

                onCalculate: {
                    // For the protection tab, we need data from both systems
                    if (transformerReady && windTurbineReady) {
                        windTurbineCalculator.refreshCalculations()
                        transformerCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }
        }
    }
    
    // Use the new FloatingTabBar component
    FloatingTabBar {
        id: tabBar
        
        // Position initially on the right side
        Component.onCompleted: {
            setPosition(10, 10)
        }
        
        // Set tab model
        tabModel: [
            { text: "Wind Turbine", icon: "⚡", index: 0 },
            { text: "Transformer", icon: "🔌", index: 1 },
            { text: "Protection", icon: "🛡️", index: 2 }
        ]
        
        // Configure appearance based on theme
        darkMode: window.modeToggled
        barColor: window.modeToggled ? "#2D2D2D" : "#4a86e8"
        textColor: "#FFFFFF"
        highlightColor: window.modeToggled ? "#505050" : "#FFFFFF"
    }
    
    // Listen for theme changes
    Connections {
        target: window
        function onModeToggledChanged() {
            var isDarkTheme = window.modeToggled
            tabBar.darkMode = isDarkTheme
            tabBar.barColor = isDarkTheme ? "#2D2D2D" : "#4a86e8"
            tabBar.highlightColor = isDarkTheme ? "#505050" : "#FFFFFF"
        }
    }
}
