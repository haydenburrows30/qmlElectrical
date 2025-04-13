import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root
    
    // Transmission line properties
    property real length: 100
    property var characteristicImpedance: QtObject { 
        property real real: 0
        property real imag: 0 
    }
    property real attenuationConstant: 0
    property real phaseConstant: 0
    
    // Reference to calculator object
    property var calculator  // Make sure this property is set from parent
    
    // Theme properties
    property bool darkMode: Universal.theme === Universal.Dark
    property color textColor: Universal.foreground
    
    // Update on property changes
    onDarkModeChanged: canvas.requestPaint()
    onTextColorChanged: canvas.requestPaint()
    onLengthChanged: canvas.requestPaint()
    onCharacteristicImpedanceChanged: canvas.requestPaint()
    onAttenuationConstantChanged: canvas.requestPaint()
    onPhaseConstantChanged: canvas.requestPaint()

    // Add calculator change handler
    onCalculatorChanged: {
        canvas.requestPaint()
    }

    // Debug rectangle to show component boundaries
    Rectangle {
        anchors.fill: parent
        border.width: 1
        border.color: "red"
        color: "transparent"
        visible: false // Set to true for debugging
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        // Make sure we repaint when the component size changes
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Component.onCompleted: {
            requestPaint()
        }

        onPaint: {
            var width = canvas.width;
            var height = canvas.height;

            // Don't try to paint if we have no size
            if (width <= 0 || height <= 0) {
                console.log("Canvas has no size, skipping paint")
                return
            }

            var ctx = getContext("2d");
            ctx.reset();

            // Define colors based on theme
            var lineColor = darkMode ? "#6CB4EE" : "#2196F3";
            var waveColor = darkMode ? "#FFA07A" : "#FF6347";
            var voltageColor = darkMode ? "#90EE90" : "#00CC00";
            var currentColor = darkMode ? "#FFD700" : "#FFA500";
            
            // Draw transmission line representation
            drawTransmissionLine(ctx, width * 0.1, height * 0.2, width * 0.8, height * 0.2, lineColor);
            
            // Draw wave propagation
            drawWavePropagation(ctx, width * 0.1, height * 0.5, width * 0.8, height * 0.2, 
                              voltageColor, currentColor);
            
            // Fix phasor diagram drawing
            var phasorSize = Math.min(width * 0.2, height * 0.2);
            drawPhasorDiagram(ctx, width * 0.7, height * 0.8, phasorSize, voltageColor, currentColor);

            // console.log("Canvas painting at size:", width, "x", height)
        }
        
        function drawTransmissionLine(ctx, x, y, width, height, color) {
            try {
                // Draw conductor lines
                ctx.strokeStyle = color;
                ctx.lineWidth = 2;
                
                // Top conductor
                ctx.beginPath();
                ctx.moveTo(x, y);
                ctx.lineTo(x + width, y);
                ctx.stroke();
                
                // Bottom conductor
                ctx.beginPath();
                ctx.moveTo(x, y + height);
                ctx.lineTo(x + width, y + height);
                ctx.stroke();
                
                // Draw distributed parameters
                var segments = 8;
                var segmentWidth = width / segments;
                
                for (var i = 0; i < segments; i++) {
                    var xPos = x + i * segmentWidth;
                    
                    // Draw inductors (series elements)
                    drawInductor(ctx, xPos, y, segmentWidth * 0.8, height * 0.2);
                    
                    // Draw capacitors (shunt elements)
                    drawCapacitor(ctx, xPos + segmentWidth/2, y + height * 0.4, height * 0.2);
                }
                
                // Safe access to calculator properties
                var zMagnitude = 0;
                var zAngle = 0;
                var subConductors = 1;
                var sil = 0;
                
                if (calculator) {
                    zMagnitude = calculator.zMagnitude || 0;
                    zAngle = calculator.zAngle || 0;
                    subConductors = calculator.subConductors || 1;
                    sil = calculator.surgeImpedanceLoading || 0;
                }
                
                // Draw bundle configuration
                if (subConductors > 1) {
                    drawBundleConductors(ctx, x, y, width, height, color);
                }
                
                // Add SIL indicator
                var silRatio = sil / 2000; // Normalize to typical values
                drawSILIndicator(ctx, x + width + 20, y, height, silRatio);
                
                // Add labels
                ctx.fillStyle = textColor.toString();
                ctx.font = "12px sans-serif";
                ctx.textAlign = "center";
                
                // Length label
                ctx.fillText(length.toFixed(0) + " km", x + width/2, y - 20);
                
                // Impedance label
                ctx.fillText("Z₀ = " + zMagnitude.toFixed(1) + "∠" + 
                            zAngle.toFixed(1) + "°", 
                            x + width/2, y + height + 30);
            } catch (e) {
                console.error("Error in drawTransmissionLine:", e);
            }
        }
        
        function drawInductor(ctx, x, y, width, height) {
            ctx.beginPath();
            var loops = 3;
            var loopWidth = width / loops;
            
            for (var i = 0; i < loops; i++) {
                ctx.arc(x + i * loopWidth + loopWidth/2, y, height/2, Math.PI, 0, false);
            }
            ctx.stroke();
        }
        
        function drawCapacitor(ctx, x, y, size) {
            // Draw plates
            ctx.beginPath();
            ctx.moveTo(x - size/2, y);
            ctx.lineTo(x + size/2, y);
            ctx.moveTo(x - size/2, y + size/2);
            ctx.lineTo(x + size/2, y + size/2);
            ctx.stroke();
        }
        
        function drawWavePropagation(ctx, x, y, width, height, vColor, iColor) {
            // Draw voltage wave
            ctx.strokeStyle = vColor;
            ctx.beginPath();
            ctx.moveTo(x, y + height/2);
            
            for (var i = 0; i <= width; i++) {
                var xPos = x + i;
                var yPos = y + height/2 + Math.sin(i/30 - canvas.width/500) * 
                          height/2 * Math.exp(-attenuationConstant * i/width);
                ctx.lineTo(xPos, yPos);
            }
            ctx.stroke();
            
            // Draw current wave (90° phase shift for inductive load)
            ctx.strokeStyle = iColor;
            ctx.beginPath();
            ctx.moveTo(x, y + height/2);
            
            for (var j = 0; j <= width; j++) {
                var xPos = x + j;
                var yPos = y + height/2 + Math.cos(j/30 - canvas.width/500) * 
                          height/2 * Math.exp(-attenuationConstant * j/width);
                ctx.lineTo(xPos, yPos);
            }
            ctx.stroke();
            
            // Add labels
            ctx.fillStyle = textColor.toString();
            ctx.font = "12px sans-serif";
            ctx.textAlign = "right";
            ctx.fillText("v(x,t)", x - 10, y + height/4);
            ctx.fillText("i(x,t)", x - 10, y + height * 3/4);
            
            // Add attenuation label
            ctx.textAlign = "left";
            ctx.fillText("α = " + attenuationConstant.toFixed(4) + " Np/km", 
                        x + width + 10, y + height/4);
            ctx.fillText("β = " + phaseConstant.toFixed(4) + " rad/km", 
                        x + width + 10, y + height * 3/4);
        }
        
        function drawPhasorDiagram(ctx, centerX, centerY, size, vColor, iColor) {
            // Calculate a safe radius value
            var phasorRadius = Math.max(10, Math.min(size/2, Math.min(canvas.width, canvas.height) * 0.15));
            
            // Draw circle
            ctx.strokeStyle = textColor.toString();
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.arc(centerX, centerY, phasorRadius, 0, 2 * Math.PI);
            ctx.stroke();
            
            // Draw axes
            ctx.beginPath();
            ctx.moveTo(centerX - phasorRadius, centerY);
            ctx.lineTo(centerX + phasorRadius, centerY);
            ctx.moveTo(centerX, centerY - phasorRadius);
            ctx.lineTo(centerX, centerY + phasorRadius);
            ctx.stroke();
            
            try {
                // Safely access calculator properties
                var zAngle = 0;
                var zMagnitude = 0;
                
                if (typeof calculator !== 'undefined' && calculator !== null) {
                    zAngle = calculator.zAngle || 0;
                    zMagnitude = calculator.zMagnitude || 0;
                }
                
                // Calculate angles
                var vAngle = zAngle * Math.PI / 180;  // Convert degrees to radians
                var vMag = Math.min(zMagnitude / 100, 1.0);  // Normalize magnitude
                
                // Draw voltage phasor
                ctx.strokeStyle = vColor;
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.moveTo(centerX, centerY);
                ctx.lineTo(centerX + phasorRadius * vMag * Math.cos(vAngle), 
                          centerY - phasorRadius * vMag * Math.sin(vAngle));
                ctx.stroke();
                
                // Draw current phasor (phase shifted)
                var iAngle = vAngle - Math.PI/2;  // 90° lag for inductive load
                ctx.strokeStyle = iColor;
                ctx.beginPath();
                ctx.moveTo(centerX, centerY);
                ctx.lineTo(centerX + phasorRadius * Math.cos(iAngle), 
                          centerY - phasorRadius * Math.sin(iAngle));
                ctx.stroke();
                
                // Add labels
                ctx.fillStyle = textColor.toString();
                ctx.font = "12px sans-serif";
                ctx.textAlign = "center";
                ctx.fillText("Phasor Diagram", centerX, centerY + phasorRadius + 20);
                
                // Add magnitude and angle labels
                ctx.fillText("|Z₀| = " + zMagnitude.toFixed(1) + " Ω", 
                            centerX, centerY + phasorRadius + 40);
                ctx.fillText("∠Z₀ = " + zAngle.toFixed(1) + "°", 
                            centerX, centerY + phasorRadius + 60);
            } catch (e) {
                console.error("Error in phasor diagram: ", e);
                // Draw fallback content if there's an error
                ctx.fillStyle = textColor.toString();
                ctx.textAlign = "center";
                ctx.fillText("Phasor diagram unavailable", centerX, centerY);
            }
        }
        
        function drawBundleConductors(ctx, x, y, width, height, color) {
            // Draw bundle spacing visualization
            // Implementation here
        }
        
        function drawSILIndicator(ctx, x, y, height, ratio) {
            // Draw SIL gauge
            // Implementation here
        }
    }
}
