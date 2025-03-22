import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Canvas {
    id: root
    
    // Input properties
    property string inputVoltage: "12"
    property string resistorR1: "10000" 
    property string resistorR2: "10000"
    property string outputVoltage: "6.000"
    property string currentValue: "0.600"
    
    // Theming properties
    property color wireColor: "#2196F3"
    property color resistorColor: "#FF5722"
    property color textColor: "#212121"
    property color batteryColor: "#4CAF50"
    property color groundColor: "#607D8B"
    property color outputColor: "#9C27B0"
    property int lineWidth: 3
    property int fontSize: 14
    property string fontFamily: "sans-serif"
    
    onInputVoltageChanged: requestPaint()
    onResistorR1Changed: requestPaint()
    onResistorR2Changed: requestPaint()
    onOutputVoltageChanged: requestPaint()
    onCurrentValueChanged: requestPaint()
    
    function formatValue(value, units) {
        // Convert value to appropriate prefix (k, M, etc.)
        if (value >= 1000000) {
            return (value / 1000000).toFixed(2) + " M" + units;
        } else if (value >= 1000) {
            return (value / 1000).toFixed(2) + " k" + units;
        } else {
            return value + " " + units;
        }
    }
    
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        
        // Setup drawing
        ctx.strokeStyle = wireColor;
        ctx.fillStyle = textColor;
        ctx.lineWidth = lineWidth;
        ctx.font = `${fontSize}px ${fontFamily}`;
        
        // Calculate dimensions
        var startX = width * 0.15;
        var startY = height / 2;
        var resistorLength = width * 0.25;
        var resistorHeight = 30;
        var wireLength = width * 0.12;
        var voutX = startX + wireLength + resistorLength;
        
        // Draw battery with better styling
        drawBattery(ctx, startX, startY, 40);
        
        // Draw Vin label
        ctx.fillStyle = batteryColor;
        ctx.font = `bold ${fontSize}px ${fontFamily}`;
        ctx.fillText("Vin = " + inputVoltage + " V", startX - 60, startY - 45);
        ctx.font = `${fontSize}px ${fontFamily}`;
        
        // Draw top wire
        ctx.strokeStyle = wireColor;
        ctx.beginPath();
        ctx.moveTo(startX, startY - 30);
        ctx.lineTo(startX + wireLength, startY - 30);
        ctx.lineTo(startX + wireLength, startY - 60);
        ctx.lineTo(voutX + wireLength, startY - 60);
        ctx.lineTo(voutX + wireLength, startY - 30);
        ctx.lineTo(voutX + wireLength + wireLength, startY - 30);
        ctx.stroke();
        
        // Draw R1 resistor
        drawResistor(ctx, startX + wireLength, startY - 30, resistorLength, resistorHeight);
        
        // R1 label
        ctx.fillStyle = resistorColor;
        ctx.font = `bold ${fontSize}px ${fontFamily}`;
        ctx.fillText("R1 = " + formatValue(parseFloat(resistorR1), "Ω"), startX + wireLength, startY - 45);
        ctx.font = `${fontSize}px ${fontFamily}`;
        
        // Draw bottom wire
        ctx.strokeStyle = wireColor;
        ctx.beginPath();
        ctx.moveTo(startX, startY + 30);
        ctx.lineTo(startX + wireLength, startY + 30);
        ctx.stroke();
        
        // Draw R2 resistor
        drawResistor(ctx, startX + wireLength, startY + 30, resistorLength, resistorHeight);
        
        // R2 label
        ctx.fillStyle = resistorColor;
        ctx.font = `bold ${fontSize}px ${fontFamily}`;
        ctx.fillText("R2 = " + formatValue(parseFloat(resistorR2), "Ω"), startX + wireLength, startY + 85);
        ctx.font = `${fontSize}px ${fontFamily}`;
        
        // Finish bottom wire
        ctx.strokeStyle = wireColor;
        ctx.beginPath();
        ctx.moveTo(voutX, startY + 45);
        ctx.lineTo(voutX + wireLength, startY + 45);
        ctx.lineTo(voutX + wireLength, startY + 30);
        ctx.lineTo(voutX + wireLength + wireLength, startY + 30);
        ctx.stroke();
        
        // Draw Vout connection
        ctx.strokeStyle = outputColor;
        ctx.beginPath();
        ctx.moveTo(voutX, startY + 45);
        ctx.lineTo(voutX, startY);
        ctx.stroke();
        
        // Draw Vout label with better positioning
        ctx.fillStyle = outputColor;
        ctx.font = `bold ${fontSize}px ${fontFamily}`;
        ctx.fillText("Vout = " + outputVoltage + " V", voutX + 10, startY);
        ctx.font = `${fontSize}px ${fontFamily}`;
        
        // Draw current indicator with arrow
        ctx.strokeStyle = "#FF9800";
        ctx.fillStyle = "#FF9800";
        drawCurrentArrow(ctx, startX + wireLength/2, startY - 100, "I = " + currentValue + " mA");
        
        // Draw ground symbol
        var groundX = voutX + wireLength + wireLength;
        var groundY = startY;
        drawGround(ctx, groundX, groundY);
    }
    
    function drawBattery(ctx, x, y, size) {
        ctx.strokeStyle = batteryColor;
        
        // Longer line
        ctx.beginPath();
        ctx.moveTo(x - size/3, y - size/2);
        ctx.lineTo(x + size/3, y - size/2);
        ctx.lineWidth = lineWidth * 1.5;
        ctx.stroke();
        ctx.lineWidth = lineWidth;
        
        // Shorter line
        ctx.beginPath();
        ctx.moveTo(x - size/5, y - size/4);
        ctx.lineTo(x + size/5, y - size/4);
        ctx.stroke();
        
        // Body
        ctx.beginPath();
        ctx.moveTo(x, y - size/2);
        ctx.lineTo(x, y + size/2);
        ctx.stroke();
        
        // Bottom line
        ctx.beginPath();
        ctx.moveTo(x - size/3, y + size/2);
        ctx.lineTo(x + size/3, y + size/2);
        ctx.stroke();
    }
    
    function drawResistor(ctx, x, y, width, height) {
        // Modern resistor symbol (rectangular with leads)
        ctx.strokeStyle = resistorColor;
        ctx.fillStyle = "#FFECB3";
        
        // Resistor body
        ctx.beginPath();
        ctx.rect(x, y - height/2, width, height);
        ctx.fill();
        ctx.stroke();
        
        // Draw internal zigzag
        ctx.beginPath();
        var segments = 5;
        var segWidth = width / segments;
        ctx.moveTo(x, y);
        for (var i = 0; i < segments; i++) {
            var yOffset = (i % 2 === 0) ? -height/4 : height/4;
            ctx.lineTo(x + (i+0.5) * segWidth, y + yOffset);
            ctx.lineTo(x + (i+1) * segWidth, y);
        }
        ctx.stroke();
    }
    
    function drawGround(ctx, x, y) {
        ctx.strokeStyle = groundColor;
        ctx.lineWidth = lineWidth;
        
        // Vertical line
        ctx.beginPath();
        ctx.moveTo(x, y - 10);
        ctx.lineTo(x, y + 10);
        ctx.stroke();
        
        // Ground lines (3 horizontal lines of decreasing width)
        for (var i = 0; i < 3; i++) {
            var width = 16 - i * 4;
            ctx.beginPath();
            ctx.moveTo(x - width/2, y + 10 + i * 5);
            ctx.lineTo(x + width/2, y + 10 + i * 5);
            ctx.stroke();
        }
    }
    
    function drawCurrentArrow(ctx, x, y, label) {
        // Arrow shape
        ctx.lineWidth = lineWidth;
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.lineTo(x + 70, y);
        ctx.lineTo(x + 60, y - 10);
        ctx.moveTo(x + 70, y);
        ctx.lineTo(x + 60, y + 10);
        ctx.stroke();
        
        // Current label
        ctx.fillStyle = "#FF9800";
        ctx.font = `bold ${fontSize}px ${fontFamily}`;
        ctx.fillText(label, x, y - 15);
    }
}
