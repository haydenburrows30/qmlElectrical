import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Item {
    id: root
    
    property var manager
    property bool darkMode: false
    
    ChartView {
        id: loadDistChart
        antialiasing: true
        theme: darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
        legend.visible: true
        legend.alignment: Qt.AlignBottom
        anchors.fill: parent
        
        PieSeries {
            id: loadSeries
        }
    }
    
    function updateLoadDistribution() {
        loadSeries.clear();

        if (!manager) {
            return;
        }
        
        let loadGroups = {};
        let totalLoad = 0;

        for (let i = 0; i < manager.circuitCount; i++) {
            let circuit = manager.getCircuitAt(i);
            if (!circuit) {
                continue;
            }

            let destType = getCircuitType(circuit.destination || "");
            let circuitId = circuit.number + ": " + circuit.destination;
            let load = circuit.load || 0;
            
            if (load > 0) {
                // Add as individual circuit if it's significant enough (>0.5 kW)
                if (load > 0.5) {
                    loadGroups[circuitId] = load;
                } else {
                    // Group very small loads by category
                    if (!loadGroups[destType + " (Other)"]) {
                        loadGroups[destType + " (Other)"] = 0;
                    }
                    loadGroups[destType + " (Other)"] += load;
                }
                totalLoad += load;
            }
        }

        for (let type in loadGroups) {
            if (loadGroups[type] > 0) {
                let percentage = ((loadGroups[type] / totalLoad) * 100).toFixed(1);
                let label = type + " (" + loadGroups[type].toFixed(2) + " kW, " + percentage + "%)";
                let slice = loadSeries.append(label, loadGroups[type]);

                slice.borderWidth = 2;
                slice.labelVisible = true;
                slice.labelPosition = PieSlice.LabelOutside;
                slice.exploded = true;
                slice.explodeDistanceFactor = 0.05;
            }
        }
        
        if (Object.keys(loadGroups).length === 0) {
            let slice = loadSeries.append("No Load Data", 1);
            slice.labelVisible = true;
        }
    }
    
    function getCircuitType(destination) {
        if (!destination) return "Other";
        destination = destination.toLowerCase();
        
        if (destination.includes("light")) return "Lighting";
        if (destination.includes("socket") || destination.includes("outlet") || destination.includes("power")) return "Power";
        if (destination.includes("hvac") || destination.includes("ac") || destination.includes("air con")) return "HVAC";
        if (destination.includes("motor") || destination.includes("pump")) return "Motors";
        if (destination.includes("db") || destination.includes("panel") || destination.includes("board")) return "Sub-Distribution";
        if (destination.includes("heat") || destination.includes("boiler")) return "Heating";
        if (destination.includes("kitchen") || destination.includes("cook")) return "Kitchen";
        if (destination.includes("it") || destination.includes("server") || destination.includes("computer")) return "IT Equipment";
        
        return "Other";
    }
    
    // Listen for changes to the circuit count
    Connections {
        target: manager
        function onCircuitCountChanged() {
            root.updateLoadDistribution();
        }
        function onTotalLoadChanged() {
            root.updateLoadDistribution();
        }
    }
    
    // Update when the component is completed
    Component.onCompleted: {
        updateLoadDistribution();
    }
}
