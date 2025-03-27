import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root
    property double resistance: 3.0
    property double reactance: 4.0
    property double impedance: 5.0
    property double phaseAngle: 53.1
    property color vectorColor: "#409eff"
    property color textColor: "black"
    property color gridColor: "#eeeeee"

    property bool darkMode: Universal.theme === Universal.Dark

    onDarkModeChanged: impedanceCanvas.requestPaint()

    Canvas {
        id: impedanceCanvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            ctx.clearRect(0, 0, width, height);
            
            // Calculate center and scale
            var centerX = width / 2;
            var centerY = height / 2;
            var maxDimension = Math.max(Math.abs(resistance), Math.abs(reactance), impedance);
            var scale = (Math.min(width, height) - 40) / (2 * maxDimension);
            
            // Draw axes
            ctx.lineWidth = 1;
            ctx.strokeStyle = textColor;  // Use the existing property name
            
            // X-axis
            ctx.beginPath();
            ctx.moveTo(10, centerY);
            ctx.lineTo(width - 10, centerY);
            ctx.stroke();
            
            // Y-axis
            ctx.beginPath();
            ctx.moveTo(centerX, height - 10);
            ctx.lineTo(centerX, 10);
            ctx.stroke();
            
            // Draw resistance (R) vector
            ctx.strokeStyle = "#ff6666";  // Red for resistance
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(centerX + resistance * scale, centerY);
            ctx.stroke();
            
            // Draw reactance (X) vector
            ctx.strokeStyle = "#6666ff";  // Blue for reactance
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(centerX, centerY - reactance * scale);
            ctx.stroke();
            
            // Draw impedance (Z) vector
            ctx.strokeStyle = darkMode ? "#90EE90" : "#007700";  // Green for impedance
            ctx.lineWidth = 3;
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(centerX + resistance * scale, centerY - reactance * scale);
            ctx.stroke();
            
            // Draw labels
            ctx.font = "14px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            
            // R label
            ctx.fillStyle = "#ff6666";  // Same as R vector
            ctx.fillText("R = " + resistance.toFixed(2) + "Ω", 
                        centerX + resistance * scale / 2,
                        centerY + 20);
            
            // X label
            ctx.fillStyle = "#6666ff";  // Same as X vector
            ctx.fillText("X = " + reactance.toFixed(2) + "Ω", 
                        centerX - 25, 
                        centerY - reactance * scale / 2);
            
            // Z label
            ctx.fillStyle = darkMode ? "#90EE90" : "#007700";  // Same as Z vector
            ctx.fillText("Z = " + impedance.toFixed(2) + "Ω ∠" + phaseAngle.toFixed(1) + "°", 
                        centerX + resistance * scale / 2,
                        centerY - reactance * scale / 2 - 10);
            
            // Axes labels
            ctx.fillStyle = textColor;  // Use the existing property name
            ctx.fillText("R", width - 15, centerY - 15);
            ctx.fillText("X", centerX + 15, 15);
        }
    }

    onResistanceChanged: impedanceCanvas.requestPaint()
    onReactanceChanged: impedanceCanvas.requestPaint()
    onImpedanceChanged: impedanceCanvas.requestPaint()
    onPhaseAngleChanged: impedanceCanvas.requestPaint()
}
