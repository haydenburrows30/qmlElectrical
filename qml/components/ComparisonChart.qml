import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

Rectangle {
    id: comparisonChart
    width: parent.width
    height: 300
    color: Universal.background
    
    property var methodNames: []
    property var currentValues: []
    property var torqueValues: []
    property var efficiencyValues: []
    property var tempRiseValues: []
    
    property string selectedMetric: "current" // "current", "torque", "efficiency", "temperature"
    
    function getMetricData() {
        switch(selectedMetric) {
            case "current": return currentValues
            case "torque": return torqueValues
            case "efficiency": return efficiencyValues
            case "temperature": return tempRiseValues
            default: return currentValues
        }
    }
    
    function getMetricColor() {
        switch(selectedMetric) {
            case "current": return Universal.accent
            case "torque": return "#FF6347" // Tomato
            case "efficiency": return "#32CD32" // Lime Green
            case "temperature": return "#FF8C00" // Dark Orange
            default: return Universal.accent
        }
    }
    
    function getMetricTitle() {
        switch(selectedMetric) {
            case "current": return "Starting Current (× FLC)"
            case "torque": return "Starting Torque (× FLT)"
            case "efficiency": return "Starting Efficiency (%)"
            case "temperature": return "Temperature Rise (°C)"
            default: return "Value"
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        Text {
            text: getMetricTitle()
            font.bold: true
            font.pixelSize: 16
            color: Universal.foreground
            Layout.alignment: Qt.AlignHCenter
        }
        
        TabBar {
            id: metricSelector
            Layout.fillWidth: true
            
            TabButton {
                text: "Current"
                onClicked: selectedMetric = "current"
            }
            TabButton {
                text: "Torque"
                onClicked: selectedMetric = "torque"
            }
            TabButton {
                text: "Efficiency"
                onClicked: selectedMetric = "efficiency"
            }
            TabButton {
                text: "Temperature"
                onClicked: selectedMetric = "temperature"
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            Canvas {
                id: chartCanvas
                anchors.fill: parent
                anchors.margins: 20
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    var width = chartCanvas.width;
                    var height = chartCanvas.height;
                    
                    var metrics = getMetricData();
                    if (!metrics || metrics.length === 0) return;
                    
                    // Find max value for scaling
                    var maxValue = 0;
                    for (var i = 0; i < metrics.length; i++) {
                        maxValue = Math.max(maxValue, metrics[i]);
                    }
                    
                    // Add 20% margin to max value
                    maxValue = maxValue * 1.2;
                    
                    // Draw background
                    ctx.fillStyle = Universal.background;
                    ctx.fillRect(0, 0, width, height);
                    
                    // Draw grid
                    ctx.strokeStyle = Qt.rgba(0.7, 0.7, 0.7, 0.3);
                    ctx.lineWidth = 1;
                    
                    // Horizontal grid lines
                    for (var j = 0; j <= 5; j++) {
                        var y = height - (j * height / 5);
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                        
                        // Add y-axis labels
                        ctx.fillStyle = Universal.foreground;
                        ctx.font = "10px sans-serif";
                        ctx.fillText((maxValue * j / 5).toFixed(1), 5, y - 5);
                    }
                    
                    // Draw bars
                    var barWidth = width / (methodNames.length * 2);
                    var barColor = getMetricColor();
                    
                    for (var k = 0; k < methodNames.length; k++) {
                        var barHeight = (metrics[k] / maxValue) * height;
                        var barX = (k * 2 + 1) * barWidth;
                        var barY = height - barHeight;
                        
                        // Draw bar
                        ctx.fillStyle = barColor;
                        ctx.fillRect(barX, barY, barWidth, barHeight);
                        
                        // Draw bar value
                        ctx.fillStyle = Universal.foreground;
                        ctx.font = "bold 12px sans-serif";
                        ctx.fillText(metrics[k].toFixed(1), barX, barY - 5);
                        
                        // Draw method name
                        ctx.save();
                        ctx.translate(barX + barWidth/2, height - 5);
                        ctx.rotate(-Math.PI/4);
                        ctx.fillText(methodNames[k], 0, 0);
                        ctx.restore();
                    }
                }
            }
        }
    }
    
    // Trigger repaint when properties change
    onMethodNamesChanged: chartCanvas.requestPaint()
    onCurrentValuesChanged: chartCanvas.requestPaint()
    onTorqueValuesChanged: chartCanvas.requestPaint()
    onEfficiencyValuesChanged: chartCanvas.requestPaint()
    onTempRiseValuesChanged: chartCanvas.requestPaint()
    onSelectedMetricChanged: chartCanvas.requestPaint()
}
