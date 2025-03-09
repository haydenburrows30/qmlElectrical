import QtQuick 2.15

Item {
    id: root
    property var yValues: []
    property double amplitude: 330
    property double frequency: 50
    property color waveColor: "#409eff"
    property color gridColor: "#eeeeee"
    property color textColor: "black"
    property double rms: 0
    property double peak: 0

    Canvas {
        id: canvas
        anchors.centerIn: parent

        width: 300
        height: 250
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var margin = 20;
            var width = canvas.width - 2 * margin;
            var height = canvas.height - 2 * margin;
            
            var centerY = margin + height / 2;
            var maxAmplitude = height / 2 * 0.9;
            
            // Draw grid
            ctx.strokeStyle = gridColor;
            ctx.lineWidth = 1;
            
            // Horizontal grid lines
            var gridSteps = 4;
            for (var i = -gridSteps; i <= gridSteps; i++) {
                var y = centerY - (i * maxAmplitude / gridSteps);
                ctx.beginPath();
                ctx.moveTo(margin, y);
                ctx.lineTo(margin + width, y);
                ctx.stroke();
                
                // Add y-axis labels
                if (i !== 0) {
                    ctx.fillStyle = textColor;
                    ctx.font = "10px sans-serif";
                    var label = (amplitude * i / gridSteps).toFixed(0);
                    ctx.fillText(label, margin - 20, y);
                }
            }
            
            // Draw center line
            ctx.strokeStyle = textColor;
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.moveTo(margin, centerY);
            ctx.lineTo(margin + width, centerY);
            ctx.stroke();
            
            // Draw sine wave
            if (yValues.length > 0) {
                ctx.strokeStyle = waveColor;
                ctx.lineWidth = 2;
                ctx.beginPath();
                
                var step = width / (yValues.length - 1);
                
                for (var j = 0; j < yValues.length; j++) {
                    var x = margin + j * step;
                    var normalizedY = -yValues[j] / amplitude * maxAmplitude;
                    var y = centerY + normalizedY;
                    
                    if (j === 0) {
                        ctx.moveTo(x, y);
                    } else {
                        ctx.lineTo(x, y);
                    }
                }
                
                ctx.stroke();
            }
            
            // Draw RMS and Peak values
            ctx.fillStyle = textColor;
            ctx.font = "12px sans-serif";
            ctx.fillText("RMS: " + rms.toFixed(1), margin + 10, margin + 20);
            ctx.fillText("Peak: " + peak.toFixed(1), margin + 10, margin + 40);
            ctx.fillText("Frequency: " + frequency.toFixed(1) + " Hz", margin + 10, margin + 60);
        }
    }

    onYValuesChanged: canvas.requestPaint()
    onAmplitudeChanged: canvas.requestPaint()
    onFrequencyChanged: canvas.requestPaint()
    onRmsChanged: canvas.requestPaint()
    onPeakChanged: canvas.requestPaint()
}
