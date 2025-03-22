import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property double apparentPower: 100
    property double powerFactor: 0.8
    property double realPower: 80
    property double reactivePower: 60
    property double phaseAngle: 36.9
    property color triangleColor: "#409eff"
    property color textColor: "black"

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var margin = 20;
            var width = canvas.width - 2 * margin;
            var height = canvas.height - 2 * margin;
            
            // Calculate triangle dimensions
            var maxDimension = Math.min(width, height) * 0.8;
            var xBase = maxDimension * powerFactor;
            var yHeight = maxDimension * Math.sin(Math.acos(powerFactor));
            
            // Center the triangle
            var centerX = canvas.width / 2;
            var centerY = canvas.height / 2;
            var startX = centerX - xBase / 2;
            var startY = centerY + yHeight / 2;
            
            // Draw triangle
            ctx.beginPath();
            ctx.moveTo(startX, startY);
            ctx.lineTo(startX + xBase, startY);
            ctx.lineTo(startX, startY - yHeight);
            ctx.closePath();
            
            ctx.lineWidth = 2;
            ctx.strokeStyle = triangleColor;
            ctx.stroke();
            
            // Draw labels
            ctx.fillStyle = textColor;
            ctx.font = "12px sans-serif";
            
            // P (Real Power) - along bottom
            ctx.fillText("P = " + realPower.toFixed(1) + " kW", 
                         startX + xBase / 2 - 30, 
                         startY + 20);
            
            // Q (Reactive Power) - along left side
            ctx.fillText("Q = " + reactivePower.toFixed(1) + " kVAr", 
                         startX - 70, 
                         startY - yHeight / 2);
            
            // S (Apparent Power) - along hypotenuse
            ctx.fillText("S = " + apparentPower.toFixed(1) + " kVA", 
                         startX + xBase / 3 - 40, 
                         startY - yHeight / 3 - 10);
            
            // Power Factor & Phase Angle
            ctx.fillText("PF = " + powerFactor.toFixed(2) + ", φ = " + phaseAngle.toFixed(1) + "°",
                         startX, 
                         startY + 40);
        }
    }

    onApparentPowerChanged: canvas.requestPaint()
    onPowerFactorChanged: canvas.requestPaint()
    onRealPowerChanged: canvas.requestPaint()
    onReactivePowerChanged: canvas.requestPaint()
    onPhaseAngleChanged: canvas.requestPaint()
}
