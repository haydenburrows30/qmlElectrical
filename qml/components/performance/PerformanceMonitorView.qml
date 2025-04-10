import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import PerformanceMonitor 1.0

Item {
    id: root
    
    width: parent ? parent.width : 400
    height: parent ? parent.height : 300
    
    property var perfMonitor: null
    
    // Auto-update timer
    Timer {
        id: updateTimer
        interval: 10000  // Update every 10 seconds
        running: root.visible
        repeat: true
        onTriggered: {
            if (perfMonitor && loggingSwitch.checked) {
                perfMonitor.getPerformanceReport();
                updateLabels();
            }
        }
    }
    
    function updateLabels() {
        if (!perfMonitor) return;
        
        // Update text-based indicators
        hitRatioText.text = (perfMonitor.hitRatio * 100).toFixed(1) + "%";
        timeSavedText.text = (perfMonitor.timeSavedMs / 1000).toFixed(2) + " seconds";
        performanceText.text = perfMonitor.performanceImprovement.toFixed(1) + "x";
        hitsText.text = perfMonitor.cacheHits;
        missesText.text = perfMonitor.cacheMisses;
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Controls for logging
        RowLayout {
            Layout.fillWidth: true
            
            Switch {
                id: loggingSwitch
                text: "Performance Logging"
                onCheckedChanged: {
                    if (perfMonitor) {
                        perfMonitor.enableLogging(checked);
                    }
                }
                Component.onCompleted: {
                    if (perfMonitor) {
                        checked = perfMonitor.isLoggingEnabled();
                    }
                }
            }
            
            Item { Layout.fillWidth: true } // spacer
            
            Button {
                text: "Refresh"
                onClicked: {
                    if (perfMonitor) {
                        perfMonitor.getPerformanceReport();
                        updateLabels();
                    }
                }
            }
            
            Button {
                text: "Export"
                onClicked: {
                    if (perfMonitor) {
                        var filePath = perfMonitor.exportReport();
                        exportToast.text = "Exported to: " + filePath;
                        exportToast.open();
                    }
                }
            }
        }
        
        // Performance metrics
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 5
            
            Label { 
                text: "Cache Hit Ratio:" 
                font.bold: true
            }
            Label { 
                id: hitRatioText
                text: "0%"
                Layout.fillWidth: true
            }
            
            Label { 
                text: "Time Saved:" 
                font.bold: true
            }
            Label { 
                id: timeSavedText
                text: "0 seconds"
                Layout.fillWidth: true
            }
            
            Label { 
                text: "Performance Improvement:" 
                font.bold: true
            }
            Label { 
                id: performanceText
                text: "0x"
                Layout.fillWidth: true
            }
            
            Label { 
                text: "Cache Hits:" 
                font.bold: true
            }
            Label { 
                id: hitsText
                text: "0"
                Layout.fillWidth: true
            }
            
            Label { 
                text: "Cache Misses:" 
                font.bold: true
            }
            Label { 
                id: missesText
                text: "0"
                Layout.fillWidth: true
            }
        }
        
        // Performance chart
        ChartView {
            id: perfChart
            title: "Cache Performance"
            antialiasing: true
            legend.visible: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            PieSeries {
                id: cachePie
                
                PieSlice {
                    id: hitSlice
                    label: "Hits"
                    value: perfMonitor ? perfMonitor.cacheHits : 0
                    color: "#41cd52"  // Green
                }
                
                PieSlice {
                    id: missSlice
                    label: "Misses" 
                    value: perfMonitor ? perfMonitor.cacheMisses : 0
                    color: "#9d9d9d"  // Gray
                }
            }
        }
        
        // Update the chart when data changes
        Connections {
            target: perfMonitor
            function onReportChanged() {
                updateLabels();
                
                // Update pie chart
                hitSlice.value = perfMonitor.cacheHits;
                missSlice.value = perfMonitor.cacheMisses;
            }
        }
    }
    
    // Toast message for export feedback
    Popup {
        id: exportToast
        width: parent.width * 0.8
        height: 40
        x: (parent.width - width) / 2
        y: parent.height - height - 20
        
        property alias text: toastText.text
        
        background: Rectangle {
            color: "#333333"
            radius: 5
            opacity: 0.9
        }
        
        contentItem: Label {
            id: toastText
            color: "white"
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
        }
        
        Timer {
            running: exportToast.visible
            interval: 3000
            onTriggered: exportToast.close()
        }
    }
    
    // Initialize on component completion
    Component.onCompleted: {
        if (perfMonitor) {
            perfMonitor.getPerformanceReport();
            updateLabels();
        }
    }
}
