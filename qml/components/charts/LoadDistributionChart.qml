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
    
    function getCircuitType(destination) {
        destination = destination.toLowerCase()
        
        if (destination.includes("light")) return "Lighting"
        if (destination.includes("socket") || destination.includes("outlet")) return "Power"
        if (destination.includes("hvac") || destination.includes("ac")) return "HVAC"
        if (destination.includes("motor")) return "Motors"
        if (destination.includes("db-") || destination.includes("panel")) return "Sub-Distribution"
        
        return "Other"
    }
    
    function updateChart() {
        if (!loadSeries) return;
        
        loadSeries.clear()
        
        let loadGroups = {}
        
        for (let i = 0; i < manager.circuits.length; i++) {
            let circuit = manager.circuits[i]
            let destType = getCircuitType(circuit.destination)
            
            if (!loadGroups[destType]) {
                loadGroups[destType] = 0
            }
            
            loadGroups[destType] += circuit.load
        }
        
        for (let type in loadGroups) {
            let slice = loadSeries.append(type, loadGroups[type])
            slice.labelVisible = true
        }
    }
    
    Connections {
        target: manager
        function onCircuitsChanged() {
            root.updateChart()
        }
    }
    
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: root.updateChart()
    }
}
