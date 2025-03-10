import QtQuick
import QtQuick.Controls

Popup {
    id: root
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: 700
    height: 700
    
    property real percentage: 0
    property string cableSize: "0"
    property real currentValue: 0
    // Expose the chart component as a read-only property
    readonly property alias chartComponent: chartComponent
    
    signal saveRequested(real scale)
    
    // Call this when the popup is about to show
    function prepareChart() {
        chartComponent.percentage = root.percentage
        chartComponent.cableSize = root.cableSize
        chartComponent.currentValue = root.currentValue
        chartComponent.updateChart()
    }
    
    // Added grabImage convenience method for external use
    function grabImage(callback, scale) {
        if (chartComponent) {
            chartComponent.grabChartImage(callback, scale)
        }
    }
    
    // Use the VoltageDropChart component
    VoltageDropChart {
        id: chartComponent
        anchors.fill: parent
        
        // Connect signals
        onCloseRequested: root.close()
        onSaveRequested: function(scale) {
            root.saveRequested(scale)
        }
    }
}
