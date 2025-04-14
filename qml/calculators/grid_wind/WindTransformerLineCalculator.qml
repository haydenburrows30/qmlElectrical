import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components/style"
import "../../components/buttons"

import TransformerLine 1.0
import WindTurbine 1.0

Item {
    id: root

    property var transformerCalculator
    property var windTurbineCalculator

    property bool transformerReady: transformerCalculator !== null
    property bool windTurbineReady: windTurbineCalculator !== null

    property real totalGeneratedPower: windTurbineReady ? windTurbineCalculator.actualPower : 0
    // property real windGeneratorCapacity: windTurbineReady ? windTurbineCalculator.actualPower * 1.2 : 0 // 20% margin
    
    Component.onCompleted: {
        transformerCalculator = Qt.createQmlObject('import QtQuick; import TransformerLine 1.0; TransformerLineCalculator {}', 
                                                 root, "dynamicTransformerCalculator");
        windTurbineCalculator = Qt.createQmlObject('import QtQuick; import WindTurbine 1.0; WindTurbineCalculator {}', 
                                                 root, "dynamicWindCalculator");
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
            
            // Tab 1: Wind Turbine Parameters - operates independently
            WindTurbineSection {
                id: windTurbineSection
                Layout.fillWidth: true
                Layout.preferredHeight: 750
                
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
                Layout.minimumHeight: 800
                
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
                Layout.preferredHeight: 2000
                
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
}
